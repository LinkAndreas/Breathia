import Foundation
import Testing
@testable import Breathia

struct SessionHistoryTests {
    private func record(_ offset: TimeInterval) -> SessionRecord {
        SessionRecord(
            id: UUID(), date: Date(timeIntervalSince1970: offset), techniqueID: "box",
            duration: 60, heartRate: nil, hrv: nil, heartRateTrace: [], source: .iPhone
        )
    }

    @Test func keepsSessionsNewestFirst() {
        let history = SessionHistory(repository: InMemorySessionRepository())
        let older = record(100), newer = record(200), middle = record(150)
        history.record(older)
        history.record(newer)
        history.record(middle)
        #expect(history.sessions.map(\.id) == [newer.id, middle.id, older.id])
    }

    /// Sessions from Apple Watch can arrive more than once.
    @Test func ignoresDuplicates() {
        let history = SessionHistory(repository: InMemorySessionRepository())
        let session = record(100)
        history.record(session)
        history.record(session)
        #expect(history.sessions.count == 1)
    }

    @Test func deletes() {
        let session = record(100)
        let history = SessionHistory(repository: InMemorySessionRepository(sessions: [session]))
        history.delete(session)
        #expect(history.sessions.isEmpty)
    }

    @Test func deletesEverySession() {
        let repository = InMemorySessionRepository(sessions: [record(100), record(200), record(300)])
        let history = SessionHistory(repository: repository)
        history.deleteAll()
        #expect(history.sessions.isEmpty)
        #expect(repository.fetchAll().isEmpty)
    }
}

struct BreathingSessionModelTests {
    private final class FakeMonitor: LiveHeartRateProviding {
        var isConnected = true
        var heartRate: Int? = 64
        var hrv: HRV? = HRV(sdnn: 40, rmssd: 50)
    }

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    private func makeSession(
        clock: Clock,
        countdown: Bool = false,
        onComplete: @escaping (SessionRecord) -> Void = { _ in }
    ) -> BreathingSessionModel {
        var settings = AppSettings()
        settings.countdownEnabled = countdown
        return BreathingSessionModel(
            technique: .testTechnique(phases: [.inhale(4), .exhale(4)], duration: 60),
            monitor: FakeMonitor(),
            settings: settings,
            source: .iPhone,
            cuePlayer: SilentBreathingCuePlayer(),
            now: { clock.now },
            onComplete: onComplete
        )
    }

    /// Lets the session's loop start.
    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    @Test func recordsASessionLongEnough() async throws {
        let clock = Clock()
        var recorded: SessionRecord?
        let session = makeSession(clock: clock) { recorded = $0 }
        session.start()
        try await settle()

        clock.now += 30
        session.end()

        #expect(session.wasRecorded)
        #expect(recorded?.duration == 30)
    }

    @Test func doesNotRecordAVeryShortSession() async throws {
        let clock = Clock()
        var recorded: SessionRecord?
        let session = makeSession(clock: clock) { recorded = $0 }
        session.start()
        try await settle()

        clock.now += BreathingSessionModel.minimumRecordedDuration - 1
        session.end()

        #expect(!session.wasRecorded)
        #expect(recorded == nil)
    }

    @Test func pausedTimeDoesNotCount() async throws {
        let clock = Clock()
        var recorded: SessionRecord?
        let session = makeSession(clock: clock) { recorded = $0 }
        session.start()
        try await settle()

        clock.now += 20
        session.togglePause()
        clock.now += 100
        session.togglePause()
        clock.now += 10
        session.end()

        #expect(recorded?.duration == 30)
    }

    @Test func neverRecordsMoreThanTheTarget() async throws {
        let clock = Clock()
        var recorded: SessionRecord?
        let session = makeSession(clock: clock) { recorded = $0 }
        session.start()
        try await settle()

        clock.now += 500
        session.end()

        #expect(recorded?.duration == 60)
    }

    // MARK: Leaving the app

    @Test func leavingPausesARunningSession() async throws {
        let clock = Clock()
        var recorded: SessionRecord?
        let session = makeSession(clock: clock) { recorded = $0 }
        session.start()
        try await settle()

        clock.now += 20
        session.interrupt()
        #expect(session.isPaused)

        clock.now += 300
        session.continueAfterInterruption()
        // Back in the app, the session waits for the user to resume.
        #expect(session.isPaused)

        session.resume()
        clock.now += 10
        session.end()
        #expect(recorded?.duration == 30)
    }

    /// Waits until the countdown has gone down from its start.
    private func waitForCountdownToMove(_ session: BreathingSessionModel) async throws {
        let deadline = ContinuousClock.now + .seconds(30)
        while session.stage == .countdown(BreathingSessionModel.countdownStart), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        guard case let .countdown(value) = session.stage else {
            Issue.record("The countdown ended instead of counting down")
            return
        }
        #expect(value < BreathingSessionModel.countdownStart)
    }

    @Test func leavingDuringTheCountdownStartsItOverOnReturn() async throws {
        let session = makeSession(clock: Clock(), countdown: true)
        session.start()
        // A busy machine may let the countdown run a little further.
        try await waitForCountdownToMove(session)

        session.interrupt()
        #expect(session.stage == .countdown(BreathingSessionModel.countdownStart))
        #expect(session.countdownStartedAt == nil)

        // While away, the countdown doesn't move.
        try await Task.sleep(for: .milliseconds(1200))
        #expect(session.stage == .countdown(BreathingSessionModel.countdownStart))

        session.continueAfterInterruption()
        try await settle()
        #expect(session.countdownStartedAt != nil)
        try await waitForCountdownToMove(session)
        session.cancel()
    }

    @Test func pauseAndResumeAreIdempotent() async throws {
        let clock = Clock()
        let session = makeSession(clock: clock)
        session.start()
        try await settle()

        session.pause()
        session.pause()
        #expect(session.isPaused)
        session.resume()
        session.resume()
        #expect(!session.isPaused)
        session.cancel()
    }
}
