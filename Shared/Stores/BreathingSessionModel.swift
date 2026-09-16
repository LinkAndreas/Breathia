import Foundation
import Observation

/// Runs one breathing session: the optional countdown, the phase clock, pausing,
/// heart-rate sampling, and — when it ends — producing the `SessionRecord`.
/// Shared by iPhone and Apple Watch; each injects its own heart-rate source, cue
/// player, and (on iPhone) the Live Activity.
@Observable
final class BreathingSessionModel {
    enum Stage: Equatable {
        case countdown(Int)
        case running
        case completed(SessionRecord)
    }

    static let countdownStart = 3
    /// Sessions ended sooner than this are shown but not recorded.
    static let minimumRecordedDuration: TimeInterval = 10
    static let liveChartCapacity = 30

    let technique: Technique
    let targetDuration: TimeInterval
    let hrvMetric: HRVMetric

    private(set) var stage: Stage
    private(set) var isPaused = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var heartRateSamples: [Int] = []
    private(set) var hrvSamples: [Double] = []
    /// Whether the finished session was long enough to be handed to `onComplete`.
    private(set) var wasRecorded = false
    /// When the current countdown began; `nil` while it waits to start (again).
    private(set) var countdownStartedAt: Date?

    @ObservationIgnored private let monitor: LiveHeartRateProviding
    @ObservationIgnored private let source: SessionSource
    @ObservationIgnored private let cuePlayer: BreathingCuePlaying
    @ObservationIgnored private let activity: SessionActivityReporting
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let onComplete: (SessionRecord) -> Void
    @ObservationIgnored private let clock: BreathingClock
    @ObservationIgnored private let analyzer: BiofeedbackAnalyzer
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var pausedAt: Date?
    @ObservationIgnored private var pausedTotal: TimeInterval = 0
    @ObservationIgnored private var lastSampledSecond = -1
    @ObservationIgnored private var lastCuedPhase: Int?
    @ObservationIgnored private var loop: Task<Void, Never>?

    init(
        technique: Technique,
        monitor: LiveHeartRateProviding,
        settings: AppSettings,
        source: SessionSource,
        cuePlayer: BreathingCuePlaying,
        activity: SessionActivityReporting = NoSessionActivity(),
        now: @escaping () -> Date = { Date() },
        onComplete: @escaping (SessionRecord) -> Void
    ) {
        self.technique = technique
        self.targetDuration = TimeInterval(technique.recommendedDuration)
        self.hrvMetric = settings.hrvMetric
        self.monitor = monitor
        self.source = source
        self.cuePlayer = cuePlayer
        self.activity = activity
        self.now = now
        self.onComplete = onComplete
        self.clock = BreathingClock(technique: technique)
        self.analyzer = BiofeedbackAnalyzer(sensitivity: settings.feedbackSensitivity)
        self.stage = settings.countdownEnabled ? .countdown(Self.countdownStart) : .running
    }

    // MARK: Derived state

    var isSensorConnected: Bool { monitor.isConnected }
    var liveHeartRate: Int? { monitor.heartRate }
    var progress: Double { min(1, elapsed / targetDuration) }
    var remaining: TimeInterval { max(0, targetDuration - elapsed) }
    var feedback: BiofeedbackAnalyzer.Feedback { analyzer.feedback(elapsed: elapsed, samples: hrvSamples) }
    var recentHeartRates: [Double] { heartRateSamples.suffix(Self.liveChartCapacity).map(Double.init) }
    var recentHRV: [Double] { Array(hrvSamples.suffix(Self.liveChartCapacity)) }

    /// Sampled every frame by the breathing circle, so it moves smoothly between
    /// the coarser model ticks and freezes while paused.
    func position(at date: Date) -> BreathingClock.Position {
        clock.position(at: activeElapsed(at: date))
    }

    // MARK: Lifecycle

    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            await self?.run()
        }
    }

    func togglePause() {
        if isPaused { resume() } else { pause() }
    }

    func pause() {
        guard stage == .running, startedAt != nil, pausedAt == nil else { return }
        pausedAt = now()
        isPaused = true
        reportActivity()
    }

    func resume() {
        guard stage == .running, let pausedAt else { return }
        pausedTotal += now().timeIntervalSince(pausedAt)
        self.pausedAt = nil
        isPaused = false
        reportActivity()
    }

    /// The session can't be followed for now — e.g. the app left the screen, where
    /// its cues and sensor readings stop. A running session pauses, so time away
    /// isn't counted; a countdown goes back to the start and waits.
    func interrupt() {
        switch stage {
        case .countdown:
            loop?.cancel()
            loop = nil
            countdownStartedAt = nil
            stage = .countdown(Self.countdownStart)
        case .running:
            pause()
        case .completed:
            break
        }
    }

    /// The session can be followed again. A countdown starts over; a paused session
    /// stays paused until the user resumes, so it never picks up mid-breath.
    func continueAfterInterruption() {
        if case .countdown = stage, loop == nil {
            start()
        }
    }

    func end() {
        guard stage == .running, let startedAt else { return }
        cancel()

        let duration = min(targetDuration, activeElapsed(at: now()))
        let record = SessionRecordFactory.makeRecord(
            technique: technique,
            startedAt: startedAt,
            duration: duration,
            heartRates: heartRateSamples,
            hrvValues: hrvSamples,
            metric: hrvMetric,
            source: source
        )
        wasRecorded = duration >= Self.minimumRecordedDuration
        stage = .completed(record)
        if wasRecorded {
            onComplete(record)
        }
    }

    /// Stops the session's clock and removes its Live Activity.
    func cancel() {
        loop?.cancel()
        loop = nil
        activity.end()
    }

    // MARK: Private

    private func run() async {
        cuePlayer.prepare()
        if case .countdown = stage {
            countdownStartedAt = now()
            for value in stride(from: Self.countdownStart, through: 1, by: -1) {
                stage = .countdown(value)
                // Keep the cues warm, so the first one doesn't stall the switch to
                // the live session when the countdown ends.
                cuePlayer.prepare()
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
        }

        startedAt = now()
        stage = .running
        reportActivity()
        tick()

        while !Task.isCancelled, stage == .running {
            try? await Task.sleep(for: .milliseconds(200))
            tick()
        }
    }

    private func tick() {
        guard stage == .running, !isPaused else { return }
        elapsed = activeElapsed(at: now())
        cueOnPhaseChange()
        sampleSensorOncePerSecond()
        if elapsed >= targetDuration {
            end()
        }
    }

    private func cueOnPhaseChange() {
        let position = clock.position(at: elapsed)
        let phaseNumber = position.cycle * technique.phases.count + position.phaseIndex
        guard phaseNumber != lastCuedPhase else { return }
        lastCuedPhase = phaseNumber
        cuePlayer.cue(position.phase)
    }

    /// Mirrors the session outside the app: sent when it starts and on pause or
    /// resume — the Live Activity's progress bar fills by itself in between.
    private func reportActivity() {
        let date = now()
        let remaining = max(0, targetDuration - activeElapsed(at: date))
        activity.update(SessionActivitySnapshot(
            technique: technique,
            sessionEndDate: date.addingTimeInterval(remaining),
            remaining: remaining,
            isPaused: isPaused
        ))
    }

    private func sampleSensorOncePerSecond() {
        let second = Int(elapsed)
        guard second != lastSampledSecond else { return }
        lastSampledSecond = second

        guard monitor.isConnected else { return }
        if let heartRate = monitor.heartRate {
            heartRateSamples.append(heartRate)
        }
        if let hrv = monitor.hrv {
            hrvSamples.append(hrvMetric.value(from: hrv))
        }
    }

    private func activeElapsed(at date: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        let reference = pausedAt ?? date
        return max(0, reference.timeIntervalSince(startedAt) - pausedTotal)
    }
}
