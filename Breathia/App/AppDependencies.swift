import OSLog
import SwiftUI

/// Composition root. Builds the object graph once — the only place that picks
/// concrete storage, Bluetooth, HealthKit, StoreKit, and WatchConnectivity types —
/// and wires navigation (`AppNavigator`), screens (`AppScreens`), and flows.
/// Nothing is put in the environment up front: each screen is handed only
/// the stores it reads.
final class AppDependencies {
    let navigator: AppNavigator
    let screens: AppScreens
    let settingsStore: SettingsStore
    /// The app's icon, which the app takes its accent color from.
    let appIconStore: AppIconStore
    #if canImport(WatchConnectivity)
    /// Retained for the app's lifetime; `nil` in previews.
    private let watchSync: PhoneWatchSync?
    #endif

    /// Every dependency is passed explicitly — no defaults — so the live app can't
    /// silently end up with a preview stand-in.
    init(
        heartRateSource: HeartRateSource,
        sessionRepository: SessionRepository,
        settingsRepository: SettingsRepository,
        mindfulMinutesService: MindfulMinutesService,
        appIconStore: AppIconStore,
        reviewPromptRepository: ReviewPromptRepository,
        feedbackMailer: FeedbackMailing,
        appMetadata: AppMetadataProviding,
        syncsWithWatch: Bool,
        showsLiveActivities: Bool
    ) {
        #if os(iOS) // ActivityKit is importable on macOS, but unavailable.
        // Live Activities left behind by a session the app was quit during.
        ActivityKitSessionActivity.endLeftoverActivities()
        #endif

        let history = SessionHistory(repository: sessionRepository)
        let store: SettingsStore
        #if canImport(WatchConnectivity)
        if syncsWithWatch {
            let sync = PhoneWatchSync(history: history)
            store = SettingsStore(repository: WatchSyncingSettingsRepository(base: settingsRepository, sync: sync))
            sync.publish(store.settings)
            watchSync = sync
        } else {
            store = SettingsStore(repository: settingsRepository)
            watchSync = nil
        }
        #else
        // A Mac has no Apple Watch link.
        store = SettingsStore(repository: settingsRepository)
        #endif

        let monitor = HeartRateMonitor(source: heartRateSource)
        let mindful = MindfulMinutesStore(service: mindfulMinutesService)
        // One audio engine for every session and for the preview in Settings.
        let cueSounds = CueSoundPlayer()
        let factory = BreathingSessionFactory(
            monitor: monitor,
            settingsStore: store,
            source: Self.sessionSource,
            recorder: SessionRecorder(keepingIn: history.record, mindfulMinutes: mindful, settingsStore: store),
            makeCuePlayer: { settings in
                SystemBreathingCuePlayer(settings: settings, sounds: cueSounds)
            },
            makeActivity: {
                #if os(iOS) // ActivityKit is importable on macOS, but unavailable.
                return showsLiveActivities ? ActivityKitSessionActivity() as SessionActivityReporting : NoSessionActivity()
                #else
                return NoSessionActivity()
                #endif
            }
        )
        let navigator = AppNavigator()
        let ratingFlow = RatingFlow(
            prompter: ReviewPrompter(
                repository: reviewPromptRepository,
                mailer: feedbackMailer,
                metadataProvider: appMetadata
            ),
            sessionHistory: history,
            navigator: navigator
        )
        screens = AppScreens(
            navigator: navigator,
            sessionHistory: history,
            settingsStore: store,
            heartRateMonitor: monitor,
            mindfulMinutes: mindful,
            appIconStore: appIconStore,
            sessionFactory: factory,
            ratingFlow: ratingFlow,
            auditionCue: CueAuditioner { sound, volume in cueSounds.audition(sound, volume: volume) }
        )

        self.navigator = navigator
        settingsStore = store
        self.appIconStore = appIconStore

        // First launch: onboarding comes up over the app. After an update, what's new.
        if !store.settings.hasCompletedOnboarding {
            navigator.showOnboarding()
        } else if WhatsNew.shouldShow(lastSeen: store.settings.lastSeenWhatsNew, hasCompletedOnboarding: true) {
            navigator.showWhatsNew()
        }
    }

    #if os(macOS)
    private static let sessionSource = SessionSource.mac
    #else
    private static let sessionSource = SessionSource.iPhone
    #endif

    static func live() -> AppDependencies {
        AppDependencies(
            heartRateSource: makeLiveHeartRateSource(),
            sessionRepository: makeSessionRepository(),
            settingsRepository: UserDefaultsSettingsRepository(),
            mindfulMinutesService: makeMindfulMinutesService(),
            appIconStore: .live(),
            reviewPromptRepository: UserDefaultsReviewPromptRepository(),
            feedbackMailer: SystemFeedbackMailer(),
            appMetadata: DeviceAppMetadataProvider(),
            syncsWithWatch: true,
            showsLiveActivities: true
        )
    }

    /// History in SwiftData on the device. If the store can't be opened, History falls back to memory
    /// for this launch so the app stays usable.
    private static func makeSessionRepository() -> SessionRepository {
        do {
            return SwiftDataSessionRepository(container: try HistoryDatabase.makeContainer())
        } catch {
            Logger(subsystem: "Breathia", category: "History")
                .fault("Opening the history store failed: \(String(describing: error), privacy: .public)")
            return InMemorySessionRepository()
        }
    }

    private static func makeMindfulMinutesService() -> MindfulMinutesService {
        #if os(macOS)
        UnavailableMindfulMinutesService()
        #else
        HealthKitMindfulMinutesService()
        #endif
    }

    /// The Simulator has no Bluetooth radio, so it gets a simulated strap instead —
    /// that keeps the live biofeedback screens exercisable during development.
    private static func makeLiveHeartRateSource() -> HeartRateSource {
        #if targetEnvironment(simulator)
        SimulatedHeartRateSource()
        #else
        BluetoothHeartRateSource(device: .polarH10, service: .heartRate)
        #endif
    }

    #if DEBUG
    static func preview(
        sessions: [SessionRecord] = PreviewData.sessions,
        hasCompletedOnboarding: Bool = true,
        heartRateSource: HeartRateSource = SimulatedHeartRateSource(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    ) -> AppDependencies {
        var settings = AppSettings()
        settings.hasCompletedOnboarding = hasCompletedOnboarding
        // Previews and screenshots start on the screen they show, not on what's new.
        settings.lastSeenWhatsNew = WhatsNew.version
        return AppDependencies(
            heartRateSource: heartRateSource,
            sessionRepository: InMemorySessionRepository(sessions: sessions),
            settingsRepository: InMemorySettingsRepository(settings: settings),
            mindfulMinutesService: InMemoryMindfulMinutesService(),
            appIconStore: .preview(),
            reviewPromptRepository: InMemoryReviewPromptRepository(),
            feedbackMailer: SystemFeedbackMailer(),
            appMetadata: DeviceAppMetadataProvider(),
            syncsWithWatch: false,
            showsLiveActivities: false
        )
    }
    #endif
}
