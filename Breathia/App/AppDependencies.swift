import NavigationKit
import OSLog
import SwiftUI

/// Composition root. Builds the object graph once — the only place that picks
/// concrete storage, Bluetooth, HealthKit, StoreKit, and WatchConnectivity types —
/// and wires navigation (`AppNavigator`), screens (`AppRoutes`), and flows.
/// Nothing is put in the environment up front: `AppRoutes` hands each screen only
/// the stores it reads.
final class AppDependencies {
    let navigator: AppNavigator
    let routeBuilder: RouteBuilder
    let settingsStore: SettingsStore
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
        supportService: SupportStoreService,
        reviewPromptRepository: ReviewPromptRepository,
        reviewRequester: ReviewRequesting,
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

        let monitor = HeartRateMonitor(source: heartRateSource, sensorName: BluetoothDevice.polarH10.name)
        let mindful = MindfulMinutesStore(service: mindfulMinutesService)
        let factory = BreathingSessionFactory(
            monitor: monitor,
            settingsStore: store,
            source: Self.sessionSource,
            recorder: SessionRecorder(keepingIn: history.record, mindfulMinutes: mindful, settingsStore: store),
            makeCuePlayer: { settings in
                SystemBreathingCuePlayer(hapticsEnabled: settings.hapticsEnabled, soundEnabled: settings.soundEnabled)
            },
            makeActivity: {
                #if os(iOS) // ActivityKit is importable on macOS, but unavailable.
                return showsLiveActivities ? ActivityKitSessionActivity() as SessionActivityReporting : NoSessionActivity()
                #else
                return NoSessionActivity()
                #endif
            }
        )
        let support = SupportStore(service: supportService)
        support.startObservingTransactions()

        let navigator = AppNavigator()
        let ratingFlow = RatingFlow(
            prompter: ReviewPrompter(
                repository: reviewPromptRepository,
                reviewRequester: reviewRequester,
                mailer: feedbackMailer,
                metadataProvider: appMetadata
            ),
            sessionHistory: history,
            navigator: navigator
        )
        let routeBuilder = RouteBuilder()
        AppRoutes(
            navigator: navigator,
            sessionHistory: history,
            settingsStore: store,
            heartRateMonitor: monitor,
            mindfulMinutes: mindful,
            supportStore: support,
            sessionFactory: factory,
            ratingFlow: ratingFlow
        )
        .register(in: routeBuilder)

        self.navigator = navigator
        self.routeBuilder = routeBuilder
        settingsStore = store

        // First launch: onboarding comes up over the app.
        if !store.settings.hasCompletedOnboarding {
            navigator.showOnboarding()
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
            mindfulMinutesService: HealthKitMindfulMinutesService(),
            supportService: StoreKitSupportService(),
            reviewPromptRepository: UserDefaultsReviewPromptRepository(),
            reviewRequester: StoreKitReviewRequester(),
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
        return AppDependencies(
            heartRateSource: heartRateSource,
            sessionRepository: InMemorySessionRepository(sessions: sessions),
            settingsRepository: InMemorySettingsRepository(settings: settings),
            mindfulMinutesService: InMemoryMindfulMinutesService(),
            supportService: PreviewSupportService(),
            reviewPromptRepository: InMemoryReviewPromptRepository(),
            reviewRequester: StoreKitReviewRequester(),
            feedbackMailer: SystemFeedbackMailer(),
            appMetadata: DeviceAppMetadataProvider(),
            syncsWithWatch: false,
            showsLiveActivities: false
        )
    }
    #endif
}
