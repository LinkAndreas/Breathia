import NavigationKit
import SwiftUI

/// Maps every route to its screen and wires what each screen reports to the
/// navigator, the stores, and flows. Screens receive data and closures, plus only
/// the stores they read — provided here, route by route, so no store is in the
/// environment where it isn't used.
final class AppRoutes: RouteModule {
    private let navigator: AppNavigator
    private let sessionHistory: SessionHistory
    private let settingsStore: SettingsStore
    private let heartRateMonitor: HeartRateMonitor
    private let mindfulMinutes: MindfulMinutesStore
    private let appIconStore: AppIconStore
    private let sessionFactory: BreathingSessionFactory
    private let ratingFlow: RatingFlow

    init(
        navigator: AppNavigator,
        sessionHistory: SessionHistory,
        settingsStore: SettingsStore,
        heartRateMonitor: HeartRateMonitor,
        mindfulMinutes: MindfulMinutesStore,
        appIconStore: AppIconStore,
        sessionFactory: BreathingSessionFactory,
        ratingFlow: RatingFlow
    ) {
        self.navigator = navigator
        self.sessionHistory = sessionHistory
        self.settingsStore = settingsStore
        self.heartRateMonitor = heartRateMonitor
        self.mindfulMinutes = mindfulMinutes
        self.appIconStore = appIconStore
        self.sessionFactory = sessionFactory
        self.ratingFlow = ratingFlow
    }

    /// Registers every route's screen. The registry's closures keep this object
    /// alive; it never holds the registry, so there's no cycle.
    func register(in registry: RouteRegistry) {
        registerBreathe(in: registry)
        registerHistory(in: registry)
        registerSettings(in: registry)
        registerModals(in: registry)
    }

    private func registerBreathe(in registry: RouteRegistry) {
        registry.register { (route: BreatheRoute, nav) in
            switch route {
            case .home:
                BreatheHomeView(
                    usesSelection: self.navigator.usesSplitLayout,
                    selectedTechniqueID: self.navigator.selectedTechniqueID,
                    onOpen: { nav.show(.technique($0)) },
                    onShowSensor: { self.navigator.showSensor() }
                )
                .contentColumnWidth()
                .environment(self.heartRateMonitor)

            case let .technique(id):
                TechniqueDetailView(technique: TechniqueCatalog.technique(withID: id)) {
                    self.navigator.startSession(with: $0, from: nav)
                }
                .id(id)
            }
        }
    }

    private func registerHistory(in registry: RouteRegistry) {
        registry.register { (route: HistoryRoute, nav) in
            switch route {
            case .list:
                HistoryListView(
                    usesSelection: self.navigator.usesSplitLayout,
                    selectedSessionID: self.navigator.selectedSessionID,
                    onOpen: { nav.show(.session($0)) },
                    onDeleted: { id in
                        if self.navigator.selectedSessionID == id {
                            nav.show(.noSelection)
                        }
                    },
                    onStartSession: { self.navigator.showBreathe() }
                )
                .contentColumnWidth()
                .environment(self.sessionHistory)

            case let .session(id):
                HistoryDetailView(sessionID: id) { session in
                    // The page already confirmed the deletion: leave it, then delete.
                    self.navigator.closeSession(from: nav)
                    self.sessionHistory.delete(session)
                }
                .id(id)
                .environment(self.sessionHistory)

            case .noSelection:
                ContentUnavailableView(
                    "history.noSelection.selectASession",
                    systemImage: "clock",
                    description: Text("history.noSelection.chooseASession")
                )
            }
        }
    }

    private func registerSettings(in registry: RouteRegistry) {
        registry.register { (route: SettingsRoute, nav) in
            switch route {
            case .home where self.navigator.usesSplitLayout:
                // The content column: the categories, like the Settings app.
                SettingsCategoryList(
                    selection: Binding(
                        get: { self.navigator.selectedSettingsPage },
                        set: { page in
                            if let page { nav.show(.page(page)) }
                        }
                    ),
                    onShowOnboarding: { self.navigator.showOnboarding() }
                )
                .contentColumnWidth()
                .environment(self.mindfulMinutes)

            case .home:
                // The tab bar: every setting in one form.
                SettingsView(
                    onShowSensor: { self.navigator.showSensor() },
                    onOpenPage: { nav.show(.page($0)) },
                    onShowOnboarding: { self.navigator.showOnboarding() }
                )
                .environment(self.heartRateMonitor)
                .environment(self.settingsStore)
                .environment(self.mindfulMinutes)
                .environment(self.appIconStore)

            case let .page(page):
                SettingsPageDestination(
                    page: page,
                    heartRateMonitor: self.heartRateMonitor,
                    settingsStore: self.settingsStore,
                    mindfulMinutes: self.mindfulMinutes,
                    appIconStore: self.appIconStore
                )
            }
        }
    }

    private func registerModals(in registry: RouteRegistry) {
        registry.register { (_: SensorRoute, nav) in
            SensorSheetView(onDone: { nav.dismiss() })
                .environment(self.heartRateMonitor)
        }

        registry.register { (route: SessionRoute, nav) in
            switch route {
            case let .run(id):
                SessionFlowView(
                    makeSession: { self.sessionFactory.makeSession(for: TechniqueCatalog.technique(withID: id)) },
                    onCancel: { nav.dismiss() },
                    onFinish: { recordedSession in
                        nav.dismiss()
                        if let recordedSession {
                            self.navigator.showHistory(with: recordedSession.id)
                            self.ratingFlow.askIfAppropriate()
                        } else {
                            self.navigator.showBreathe()
                        }
                    }
                )
                #if os(macOS)
                // A sheet on the Mac: large enough for the breathing circle.
                .frame(minWidth: 560, idealWidth: 720, minHeight: 680, idealHeight: 760)
                #endif
            }
        }

        registry.register { (_: OnboardingRoute, nav) in
            OnboardingView(
                healthAccess: HealthAccessStep.make(mindfulMinutes: self.mindfulMinutes, settingsStore: self.settingsStore),
                completion: {
                    self.settingsStore.completeOnboarding()
                    nav.dismiss()
                }
            )
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            #if os(macOS)
            // Room for the illustrations and two-line descriptions in the Mac sheet.
            .frame(minWidth: 520, idealWidth: 560, minHeight: 680, idealHeight: 720)
            #endif
            .presentationSizing(.form)
            .interactiveDismissDisabled()
        }
    }
}
