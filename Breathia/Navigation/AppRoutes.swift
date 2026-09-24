import NavigationKit
import SwiftUI

/// Maps every route to its screen and wires what each screen reports to the
/// navigator, the stores, and flows. Screens receive data and closures, plus only
/// the stores they read — provided here, route by route, so no store is in the
/// environment where it isn't used.
final class AppRoutes {
    private let navigator: AppNavigator
    private let sessionHistory: SessionHistory
    private let settingsStore: SettingsStore
    private let heartRateMonitor: HeartRateMonitor
    private let mindfulMinutes: MindfulMinutesStore
    private let supportStore: SupportStore
    private let sessionFactory: BreathingSessionFactory
    private let ratingFlow: RatingFlow

    init(
        navigator: AppNavigator,
        sessionHistory: SessionHistory,
        settingsStore: SettingsStore,
        heartRateMonitor: HeartRateMonitor,
        mindfulMinutes: MindfulMinutesStore,
        supportStore: SupportStore,
        sessionFactory: BreathingSessionFactory,
        ratingFlow: RatingFlow
    ) {
        self.navigator = navigator
        self.sessionHistory = sessionHistory
        self.settingsStore = settingsStore
        self.heartRateMonitor = heartRateMonitor
        self.mindfulMinutes = mindfulMinutes
        self.supportStore = supportStore
        self.sessionFactory = sessionFactory
        self.ratingFlow = ratingFlow
    }

    /// Registers every route's screen. The builder's closures keep this object
    /// alive; it never holds the builder, so there's no cycle.
    func register(in routeBuilder: RouteBuilder) {
        registerSidebar(in: routeBuilder)
        registerBreathe(in: routeBuilder)
        registerHistory(in: routeBuilder)
        registerSettings(in: routeBuilder)
        registerModals(in: routeBuilder)
    }

    private func registerSidebar(in routeBuilder: RouteBuilder) {
        routeBuilder.register(AppSidebarRoute.self) { _, _ in
            AppSidebarScreen(selection: self.navigator.sectionSelection)
        }
    }

    private func registerBreathe(in routeBuilder: RouteBuilder) {
        routeBuilder.register(BreatheRoute.self) { route, stack in
            switch route {
            case .home:
                BreatheHomeView(
                    usesSelection: self.navigator.usesSplitLayout,
                    selectedTechniqueID: self.navigator.selectedTechniqueID,
                    onOpen: { self.navigator.openTechnique($0, from: stack) },
                    onShowSensor: { self.navigator.showSensor() }
                )
                .contentColumnWidth()
                .environment(self.heartRateMonitor)

            case let .technique(id):
                TechniqueDetailView(technique: TechniqueCatalog.technique(withID: id)) {
                    self.navigator.startSession(with: $0, from: stack)
                }
                #if os(iOS)
                // Give the page and its floating Start button the whole screen on
                // iPhone; the split layout has no tab bar to hide.
                .toolbar(.hidden, for: .tabBar)
                #endif
                .id(id)
            }
        }
    }

    private func registerHistory(in routeBuilder: RouteBuilder) {
        routeBuilder.register(HistoryRoute.self) { route, stack in
            switch route {
            case .list:
                HistoryListView(
                    usesSelection: self.navigator.usesSplitLayout,
                    selectedSessionID: self.navigator.selectedSessionID,
                    onOpen: { self.navigator.showDetail(HistoryRoute.session($0), from: stack) },
                    onDeleted: { id in
                        if self.navigator.selectedSessionID == id {
                            self.navigator.showDetail(HistoryRoute.noSelection, from: stack)
                        }
                    },
                    onStartSession: { self.navigator.showBreathe() }
                )
                .contentColumnWidth()
                .environment(self.sessionHistory)

            case let .session(id):
                HistoryDetailView(sessionID: id) { session in
                    // The page already confirmed the deletion: leave it, then delete.
                    self.navigator.closeDetail(replacingWith: HistoryRoute.noSelection, from: stack)
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

    private func registerSettings(in routeBuilder: RouteBuilder) {
        routeBuilder.register(SettingsRoute.self) { route, stack in
            switch route {
            case .form:
                SettingsView(
                    onShowSupport: { self.navigator.showSupport() },
                    onShowSensor: { self.navigator.showSensor() },
                    onOpenPage: { stack.push(SettingsRoute.page($0)) },
                    onShowOnboarding: { self.navigator.showOnboarding() }
                )
                .environment(self.heartRateMonitor)
                .environment(self.settingsStore)
                .environment(self.mindfulMinutes)
                .environment(self.supportStore)

            case .categories:
                SettingsCategoryList(
                    selection: Binding(
                        get: { self.navigator.selectedSettingsPage },
                        set: { page in
                            if let page { self.navigator.showDetail(SettingsRoute.page(page), from: stack) }
                        }
                    ),
                    onShowSupport: { self.navigator.showSupport() },
                    onShowOnboarding: { self.navigator.showOnboarding() }
                )
                .contentColumnWidth()
                .environment(self.mindfulMinutes)
                .environment(self.supportStore)

            case let .page(page):
                SettingsPageDestination(
                    page: page,
                    heartRateMonitor: self.heartRateMonitor,
                    settingsStore: self.settingsStore,
                    mindfulMinutes: self.mindfulMinutes
                )
            }
        }
    }

    private func registerModals(in routeBuilder: RouteBuilder) {
        routeBuilder.register(SensorRoute.self) { _, stack in
            SensorSheetView(onDone: stack.dismiss)
                .environment(self.heartRateMonitor)
        }

        routeBuilder.register(SupportRoute.self) { _, stack in
            SupportSheetView(onClose: stack.dismiss)
                .environment(self.supportStore)
        }

        routeBuilder.register(SessionRoute.self) { route, stack in
            switch route {
            case let .run(id):
                SessionFlowView(
                    makeSession: { self.sessionFactory.makeSession(for: TechniqueCatalog.technique(withID: id)) },
                    onCancel: stack.dismiss,
                    onFinish: { recordedSession in
                        stack.dismiss()
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

        routeBuilder.register(OnboardingRoute.self) { _, stack in
            OnboardingView(
                healthAccess: HealthAccessStep.make(mindfulMinutes: self.mindfulMinutes, settingsStore: self.settingsStore),
                completion: {
                    self.settingsStore.completeOnboarding()
                    stack.dismiss()
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
