import Foundation

/// Composition root of the watch app: the only place that picks concrete
/// infrastructure (HealthKit, WatchConnectivity, WatchKit haptics). Screens get
/// the router and the session runner passed in; nothing is put in the environment.
final class WatchDependencies {
    let router = WatchRouter()
    let sessionRunner: WatchSessionRunner
    /// Retained for the app's lifetime.
    private let phoneSync: WatchPhoneSync

    init(
        settingsRepository: SettingsRepository = UserDefaultsSettingsRepository(),
        workout: WorkoutSessionControlling = WorkoutHeartRateProvider(),
        mindfulMinutesService: MindfulMinutesService = HealthKitMindfulMinutesService()
    ) {
        let settingsStore = SettingsStore(repository: settingsRepository)
        let sync = WatchPhoneSync(settingsStore: settingsStore)
        // Recorded sessions go to iPhone's History; the watch saves its own
        // mindful minutes, so iPhone never writes them a second time.
        let recorder = SessionRecorder(
            keepingIn: sync.send,
            mindfulMinutes: MindfulMinutesStore(service: mindfulMinutesService),
            settingsStore: settingsStore
        )

        phoneSync = sync
        sessionRunner = WatchSessionRunner(
            workout: workout,
            factory: BreathingSessionFactory(
                monitor: workout,
                settingsStore: settingsStore,
                source: .watch,
                recorder: recorder,
                makeCuePlayer: { WatchBreathingCuePlayer(hapticsEnabled: $0.hapticsEnabled) }
            )
        )
    }
}
