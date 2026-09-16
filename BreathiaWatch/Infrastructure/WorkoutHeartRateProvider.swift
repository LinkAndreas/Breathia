import Foundation
import HealthKit
import Observation
import OSLog

/// Live heart rate from the watch's own sensor, via a Mind & Body workout session.
/// The workout also keeps the app in front for the length of the session and
/// records it in the Health app.
@Observable
final class WorkoutHeartRateProvider: WorkoutSessionControlling {
    private(set) var heartRate: Int?
    private(set) var isRunning = false

    var isConnected: Bool { isRunning }
    /// The watch reports heart rate only, not beat-to-beat intervals.
    var hrv: HRV? { nil }

    /// Read without prompting: whether saving workouts is still undecided.
    var needsAuthorization: Bool {
        HKHealthStore.isHealthDataAvailable()
            && healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .notDetermined
    }

    @ObservationIgnored private let healthStore = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored private var delegateProxy: WorkoutDelegateProxy?
    @ObservationIgnored private let logger = Logger(subsystem: "Breathia", category: "Workout")

    private static let heartRateType = HKQuantityType(.heartRate)

    /// Asks once for everything the watch app writes and reads — workouts, mindful
    /// minutes, and heart rate — so the user sees a single Health sheet.
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await healthStore.requestAuthorization(
                toShare: [HKObjectType.workoutType(), HealthKitMindfulMinutesService.mindfulSessionType],
                read: [Self.heartRateType]
            )
        } catch {
            logger.error("Requesting Health access failed: \(String(describing: error), privacy: .public)")
        }
    }

    func start() async {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            let proxy = WorkoutDelegateProxy(
                onHeartRate: { [weak self] bpm in self?.heartRate = Int(bpm.rounded()) },
                onFailure: { [weak self] in self?.isRunning = false }
            )
            session.delegate = proxy
            builder.delegate = proxy

            self.session = session
            self.builder = builder
            self.delegateProxy = proxy

            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
            // `stop` may have run while collection was starting.
            isRunning = self.session != nil
        } catch {
            logger.error("Starting the workout failed: \(String(describing: error), privacy: .public)")
            self.session = nil
            self.builder = nil
            self.delegateProxy = nil
        }
    }

    func stop(save: Bool) async {
        guard let session, let builder else { return }
        self.session = nil
        self.builder = nil
        delegateProxy = nil
        isRunning = false
        heartRate = nil

        session.end()
        do {
            try await builder.endCollection(at: .now)
            if save {
                _ = try await builder.finishWorkout()
            } else {
                builder.discardWorkout()
            }
        } catch {
            logger.error("Ending the workout failed: \(String(describing: error), privacy: .public)")
        }
    }
}

/// Receives HealthKit's delegate callbacks, which arrive on background queues,
/// and forwards the values to the main actor.
private nonisolated final class WorkoutDelegateProxy: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    private let onHeartRate: @MainActor @Sendable (Double) -> Void
    private let onFailure: @MainActor @Sendable () -> Void

    init(
        onHeartRate: @escaping @MainActor @Sendable (Double) -> Void,
        onFailure: @escaping @MainActor @Sendable () -> Void
    ) {
        self.onHeartRate = onHeartRate
        self.onFailure = onFailure
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRateType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRateType),
              let quantity = workoutBuilder.statistics(for: heartRateType)?.mostRecentQuantity() else { return }

        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let onHeartRate = onHeartRate
        Task { @MainActor in onHeartRate(bpm) }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        let onFailure = onFailure
        Task { @MainActor in onFailure() }
    }
}
