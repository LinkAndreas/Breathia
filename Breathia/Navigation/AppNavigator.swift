import NavigationKit
import SwiftUI

/// Where the user is in the app, and the intents that move them — built on
/// NavigationKit: a tab bar when the window is narrow, a three-column split view
/// when it is wide. NavigationKit handles most differences between the two: `show`
/// opens the detail column or pushes, each section keeps its columns, and switching
/// layout carries an opened page across. The intents here cover what's left.
///
/// Knows routes, not screens or stores: `AppRoutes` decides what each route shows.
@Observable
final class AppNavigator {
    let store: NavigationStore

    /// Whether the window is wide enough for the split view; `nil` until the app is on
    /// screen. Reported by `AppRootView` from the same size class NavigationKit uses.
    private(set) var isRegularWidth: Bool?

    /// Onboarding asked for before the app is on screen. Whether it covers the
    /// screen or comes up as a sheet depends on the layout, which isn't known yet.
    @ObservationIgnored private var isOnboardingPending = false

    init() {
        store = NavigationStore(layout: .adaptive, selection: AppTab.breathe, sections: [
            RootSection(AppTab.breathe, AppTab.breathe.title, icon: AppTab.breathe.systemImage) {
                BreatheRoute.home
            } detail: {
                BreatheRoute.technique(TechniqueCatalog.defaultTechniqueID)
            },
            RootSection(AppTab.history, AppTab.history.title, icon: AppTab.history.systemImage) {
                HistoryRoute.list
            } detail: {
                HistoryRoute.noSelection
            },
            RootSection(AppTab.settings, AppTab.settings.title, icon: AppTab.settings.systemImage) {
                SettingsRoute.home
            } detail: {
                SettingsRoute.page(.sensor)
            },
        ])
    }

    /// Whether the split view is on screen, where lists keep a selection.
    var usesSplitLayout: Bool { isRegularWidth == true }

    func windowWidthDidChange(isRegular: Bool) {
        isRegularWidth = isRegular
        if isOnboardingPending {
            isOnboardingPending = false
            showOnboarding()
        }
    }

    // MARK: List → detail

    /// The route in `section`'s detail column, if it is of type `R`. Always `nil` in
    /// the tab bar, where lists keep no selection.
    private func selectedDetail<R: Route>(in section: AppTab, as type: R.Type) -> R? {
        guard usesSplitLayout, let index = AppTab.allCases.firstIndex(of: section) else { return nil }
        return store.snapshot.sections[index]?.detail?.root.as(R.self)
    }

    var selectedSessionID: SessionRecord.ID? {
        if case let .session(id)? = selectedDetail(in: .history, as: HistoryRoute.self) { return id }
        return nil
    }

    var selectedTechniqueID: Technique.ID? {
        if case let .technique(id)? = selectedDetail(in: .breathe, as: BreatheRoute.self) { return id }
        return nil
    }

    var selectedSettingsPage: SettingsPage? {
        if case let .page(page)? = selectedDetail(in: .settings, as: SettingsRoute.self) { return page }
        return nil
    }

    /// Leaves a session page that no longer applies (e.g. a deleted session).
    func closeSession(from nav: any Navigator) {
        if usesSplitLayout {
            nav.show(HistoryRoute.noSelection)
        } else {
            nav.pop()
        }
    }

    // MARK: Modals

    /// Starts a session over the app, where it keeps running if the layout changes
    /// underneath. In the tab bar, the Breathe tab returns to its list behind the
    /// session, so the technique page isn't still open afterwards.
    func startSession(with technique: Technique, from nav: any Navigator) {
        if !usesSplitLayout {
            nav.popToRoot()
        }
        nav.present(SessionRoute.run(technique.id))
    }

    func showSensor() {
        store.navigator.present(SensorRoute.connect)
    }

    func showSupport() {
        store.navigator.present(SupportRoute.support)
    }

    /// Presents onboarding — on first launch, and again from Settings. Full screen
    /// over the tab bar; a form sheet over the split view.
    func showOnboarding() {
        guard let isRegularWidth else {
            isOnboardingPending = true
            return
        }
        store.navigator.present(OnboardingRoute.welcome, as: isRegularWidth ? .sheet : .cover)
    }

    /// Asks a question over the whole app and returns the chosen action's ID.
    func dialog(_ dialog: Dialog) async -> Dialog.Action.ID? {
        await store.navigator.dialog(dialog)
    }

    // MARK: Sections

    /// Returns to Breathe, ready for the next session.
    func showBreathe() {
        store.navigator.select(AppTab.breathe)
    }

    /// Shows History after a session: the list with the new session on top in the
    /// tab bar; in the split view, that session also opens in the detail column.
    func showHistory(with sessionID: SessionRecord.ID) {
        var steps: [Step] = [.select(AppTab.history)]
        if usesSplitLayout {
            steps.append(.show(HistoryRoute.session(sessionID)))
        }
        store.navigator.navigate(steps)
    }
}

#if DEBUG
extension AppNavigator {
    /// Opens the screen asked for with `-screenshot`, once the layout is on screen.
    func showForScreenshots() async {
        guard let screen = ScreenshotScreen.requested else { return }
        try? await Task.sleep(for: .seconds(1))
        let technique = BreatheRoute.technique(ScreenshotScreen.techniqueID)
        let session = PreviewData.sessions[0]
        let nav = store.navigator
        switch screen {
        case .breathe:
            showBreathe()
        case .technique:
            nav.navigate([.select(AppTab.breathe), .show(technique)])
        case .session:
            nav.navigate(
                [.select(AppTab.breathe)]
                    + (usesSplitLayout ? [.show(technique)] : [])
                    + [.present(SessionRoute.run(ScreenshotScreen.techniqueID))]
            )
        case .history:
            showHistory(with: session.id)
        case .historyDetail:
            nav.navigate([.select(AppTab.history), .show(HistoryRoute.session(session.id))])
        case .settings:
            nav.navigate(
                [.select(AppTab.settings)] + (usesSplitLayout ? [.show(SettingsRoute.page(.breathing))] : [])
            )
        case .sensor:
            showSensor()
        case .support:
            showSupport()
        }
    }
}
#endif

extension View {
    /// Width of the content column (the section's list) on iPad and Mac.
    func contentColumnWidth() -> some View {
        navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 480)
            #if os(macOS)
            // The column is a navigation stack, whose width preference macOS doesn't
            // pass on to the split view; a minimum frame keeps the list from collapsing.
            .frame(minWidth: 320, idealWidth: 380)
            #endif
    }
}
