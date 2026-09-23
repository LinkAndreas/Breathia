import NavigationKit
import SwiftUI

/// Where the user is in the app, and the intents that move them — built on
/// NavigationKit: a tab bar when the window is narrow, a three-column split view
/// when it is wide. Each intent handles the difference between the two layouts, so
/// screens and flows never check which one is active.
///
/// Knows routes, not screens or stores: `AppRoutes` decides what each route shows.
/// The layout follows the window's width while the app runs — unfolding an iPhone,
/// resizing an iPad window, turning a large iPhone sideways — so modals are presented
/// over both layouts, where a switch doesn't dismiss them.
final class AppNavigator {
    let root: RootNavigator

    private let adaptive: AdaptiveNavigator

    /// The tab bar, while the window is narrow.
    private var tabs: TabsNavigator? { adaptive.activeTabs }

    /// The split view, while the window is wide.
    private var split: SplitNavigator? { adaptive.activeSplit }

    /// The technique whose details the Breathe detail column returns to — the
    /// one last opened or started, or the catalog's default.
    private var lastTechniqueID: Technique.ID?

    /// Onboarding asked for before the app is on screen. Whether it covers the
    /// screen or comes up as a sheet depends on the layout, which isn't known yet.
    private var isOnboardingPending = false

    init() {
        let tabs = TabsNavigator(
            tabs: AppTab.allCases.map { tab in
                TabsNavigator.Tab(
                    id: tab,
                    title: tab.titleKey,
                    systemImage: tab.systemImage,
                    navigator: tab.makeTabNavigator()
                )
            },
            selection: AppTab.breathe
        )
        let split = SplitNavigator(
            sidebar: StackNavigator(root: AppSidebarRoute.sections),
            content: StackNavigator(root: BreatheRoute.home),
            detail: StackNavigator(root: BreatheRoute.technique(TechniqueCatalog.defaultTechniqueID)),
            columnVisibility: .all,
            sidebarColumnWidth: Self.sidebarColumnWidth
        )
        adaptive = AdaptiveNavigator(compact: tabs, regular: split)
        root = .adaptive(adaptive)
        adaptive.onLayoutChange = { [unowned self] old, new in
            layoutDidChange(from: old, to: new)
        }
    }

    /// Whether the split view is on screen, where lists keep a selection.
    var usesSplitLayout: Bool { split != nil }

    #if os(macOS)
    /// Room for the section names beside their icons; the Mac's default sidebar is narrow.
    private static let sidebarColumnWidth: SidebarColumnWidth? = SidebarColumnWidth(min: 200, ideal: 220, max: 300)
    #else
    private static let sidebarColumnWidth: SidebarColumnWidth? = nil
    #endif

    // MARK: List → detail

    /// Opens `route` as the detail of a list: in the detail column of the split view,
    /// pushed onto the list's own stack in the tab bar.
    func showDetail<R: Hashable>(_ route: R, from stack: StackNavigator) {
        if let split {
            split.showDetail(route)
        } else {
            stack.push(route)
        }
    }

    /// Leaves a detail that no longer applies (e.g. a deleted session).
    func closeDetail<R: Hashable>(replacingWith placeholder: R, from stack: StackNavigator) {
        if let split {
            split.showDetail(placeholder)
        } else {
            stack.pop()
        }
    }

    /// The route in the detail column, if it is of type `R`. Always `nil` in the
    /// tab bar, where lists keep no selection.
    func selectedDetail<R: Hashable>(as type: R.Type) -> R? {
        split?.detail.root.wrapped.base as? R
    }

    var selectedSessionID: SessionRecord.ID? {
        if case let .session(id)? = selectedDetail(as: HistoryRoute.self) { return id }
        return nil
    }

    var selectedTechniqueID: Technique.ID? {
        if case let .technique(id)? = selectedDetail(as: BreatheRoute.self) { return id }
        return nil
    }

    var selectedSettingsPage: SettingsPage? {
        if case let .page(page)? = selectedDetail(as: SettingsRoute.self) { return page }
        return nil
    }

    /// Shows a technique's details and remembers it, so returning to Breathe in the
    /// split view shows it again.
    func openTechnique(_ id: Technique.ID, from stack: StackNavigator) {
        lastTechniqueID = id
        showDetail(BreatheRoute.technique(id), from: stack)
    }

    // MARK: Modals

    /// Starts a session over the app, where it keeps running if the layout changes
    /// underneath. In the tab bar, the Breathe tab returns to its list behind the
    /// session, so the technique page isn't still open afterwards.
    func startSession(with technique: Technique, from stack: StackNavigator) {
        lastTechniqueID = technique.id
        adaptive.present(fullScreenCover: SessionRoute.run(technique.id))
        if split == nil {
            stack.popToRoot()
        }
    }

    func showSensor() {
        adaptive.present(sheet: SensorRoute.connect)
    }

    func showSupport() {
        adaptive.present(sheet: SupportRoute.support)
    }

    /// Presents onboarding — on first launch, and again from Settings. Full screen
    /// over the tab bar; a form sheet over the split view.
    func showOnboarding() {
        switch adaptive.layout {
        case .compact:
            adaptive.present(fullScreenCover: OnboardingRoute.welcome)
        case .regular:
            adaptive.present(sheet: OnboardingRoute.welcome)
        case nil:
            isOnboardingPending = true
        }
    }

    /// Presents an alert over the whole app (tab bar or split view).
    func present(alert: AlertSpec) {
        adaptive.present(alert: alert)
    }

    // MARK: Sections

    /// Returns to Breathe, ready for the next session.
    func showBreathe() {
        tabs?.select(AppTab.breathe)
        if let split { show(.breathe, in: split) }
    }

    /// Shows History after a session: the list with the new session on top in the
    /// tab bar; in the split view, that session also opens in the detail column.
    func showHistory(with sessionID: SessionRecord.ID) {
        if let tabs {
            tabs.navigator(for: AppTab.history)?.popToRoot()
            tabs.select(AppTab.history)
        }
        if let split {
            split.showContent(HistoryRoute.list)
            split.showDetail(HistoryRoute.session(sessionID))
        }
    }

    /// The sidebar's selection, derived from the content column.
    var sectionSelection: Binding<AppTab?> {
        Binding(
            get: { [unowned self] in
                split?.content.flatMap { section(showing: $0.root) }
            },
            set: { [unowned self] section in
                guard let section, let split else { return }
                show(section, in: split)
            }
        )
    }

    private func show(_ section: AppTab, in split: SplitNavigator) {
        switch section {
        case .breathe:
            split.showContent(BreatheRoute.home)
            split.showDetail(BreatheRoute.technique(lastTechniqueID ?? TechniqueCatalog.defaultTechniqueID))
        case .history:
            split.showContent(HistoryRoute.list)
            split.showDetail(HistoryRoute.noSelection)
        case .settings:
            split.showContent(SettingsRoute.categories)
            split.showDetail(SettingsRoute.page(.sensor))
        }
    }

    // MARK: Layout changes

    /// Carries what the user is looking at into the layout that just came on screen.
    private func layoutDidChange(from oldLayout: AdaptiveLayout?, to newLayout: AdaptiveLayout) {
        guard oldLayout != nil else {
            // First shown: the layout is known now.
            if isOnboardingPending {
                isOnboardingPending = false
                showOnboarding()
            }
            return
        }
        switch newLayout {
        case .regular: moveToSplit(from: adaptive.compact, into: adaptive.regular)
        case .compact: moveToTabs(from: adaptive.regular, into: adaptive.compact)
        }
    }

    /// Shows the selected tab's section, with the page the tab had open, if any, in
    /// the detail column.
    private func moveToSplit(from tabs: TabsNavigator, into split: SplitNavigator) {
        guard let section = tabs.selection?.base as? AppTab,
              let stack = tabs.navigator(for: section) else { return }
        if case let .technique(id)? = stack.path.first?.wrapped.base as? BreatheRoute {
            lastTechniqueID = id
        }
        show(section, in: split)
        if let openedPage = stack.path.first?.wrapped.base as? any Hashable {
            split.showDetail(openedPage)
            split.detail.path = Array(stack.path.dropFirst())
        }
    }

    /// Selects the sidebar section's tab at its list. Only a History session carries
    /// over as an open page: the Breathe and Settings detail columns always show a
    /// page, chosen or not, and opening one on the way would hide the list.
    private func moveToTabs(from split: SplitNavigator, into tabs: TabsNavigator) {
        guard let section = split.content.flatMap({ section(showing: $0.root) }),
              let stack = tabs.navigator(for: section) else { return }
        tabs.select(section)
        stack.popToRoot()
        if case let .session(id)? = split.detail.root.wrapped.base as? HistoryRoute {
            stack.push(HistoryRoute.session(id))
            stack.path.append(contentsOf: split.detail.path)
        }
    }

    private func section(showing root: AnyRoute) -> AppTab? {
        switch root {
        case AnyRoute(BreatheRoute.home): .breathe
        case AnyRoute(HistoryRoute.list): .history
        case AnyRoute(SettingsRoute.categories): .settings
        default: nil
        }
    }
}

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
