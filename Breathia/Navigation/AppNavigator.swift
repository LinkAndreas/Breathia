import NavigationKit
import SwiftUI

/// Where the user is in the app, and the intents that move them — built on
/// NavigationKit: a tab bar on iPhone, a three-column split view on iPad. Each
/// intent handles the difference between the two layouts, so screens and flows
/// never check which one is active.
///
/// Knows routes, not screens or stores: `AppRoutes` decides what each route shows.
/// A `RootNavigator`'s shape is fixed for its lifetime, so the layout is chosen
/// once, by the composition root, from the device idiom.
final class AppNavigator {
    let root: RootNavigator

    private let tabs: TabsNavigator?
    private let split: SplitNavigator?

    /// The technique whose details the iPad Breathe detail column returns to — the
    /// one last opened or started, or the catalog's default.
    private var lastTechniqueID: Technique.ID?

    init(usesSplitLayout: Bool) {
        if usesSplitLayout {
            let split = SplitNavigator(
                sidebar: StackNavigator(root: AppSidebarRoute.sections),
                content: StackNavigator(root: BreatheRoute.home),
                detail: StackNavigator(root: BreatheRoute.technique(TechniqueCatalog.defaultTechniqueID)),
                columnVisibility: .all,
                sidebarColumnWidth: Self.sidebarColumnWidth
            )
            self.split = split
            self.tabs = nil
            self.root = .split(split)
        } else {
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
            self.tabs = tabs
            self.split = nil
            self.root = .tabs(tabs)
        }
    }

    var usesSplitLayout: Bool { split != nil }

    #if os(macOS)
    /// Room for the section names beside their icons; the Mac's default sidebar is narrow.
    private static let sidebarColumnWidth: SidebarColumnWidth? = SidebarColumnWidth(min: 200, ideal: 220, max: 300)
    #else
    private static let sidebarColumnWidth: SidebarColumnWidth? = nil
    #endif

    // MARK: List → detail

    /// Opens `route` as the detail of a list: in the detail column on iPad, pushed
    /// onto the list's own stack on iPhone.
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

    /// The route in the iPad detail column, if it is of type `R`. Always `nil` on
    /// iPhone, where lists keep no selection.
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

    /// Shows a technique's details and remembers it, so returning to Breathe on
    /// iPad shows it again.
    func openTechnique(_ id: Technique.ID, from stack: StackNavigator) {
        lastTechniqueID = id
        showDetail(BreatheRoute.technique(id), from: stack)
    }

    // MARK: Modals

    /// Starts a session over the app. On iPhone, the Breathe tab returns to its list
    /// behind the session, so the technique page isn't still open afterwards.
    func startSession(with technique: Technique, from stack: StackNavigator) {
        lastTechniqueID = technique.id
        stack.present(fullScreenCover: SessionRoute.run(technique.id))
        if split == nil {
            stack.popToRoot()
        }
    }

    func showSensor(from stack: StackNavigator) {
        stack.present(sheet: SensorRoute.connect)
    }

    func showSupport(from stack: StackNavigator) {
        stack.present(sheet: SupportRoute.support)
    }

    /// Presents onboarding — on first launch, and again from Settings. Full screen
    /// on iPhone; a form sheet over the split view on iPad.
    func showOnboarding() {
        if let split {
            split.present(sheet: OnboardingRoute.welcome)
        } else if let tabs {
            tabs.present(fullScreenCover: OnboardingRoute.welcome)
        }
    }

    /// Presents an alert over the whole app (tab bar or split view).
    func present(alert: AlertSpec) {
        if let tabs {
            tabs.present(alert: alert)
        } else if let split {
            split.present(alert: alert)
        }
    }

    // MARK: Sections

    /// Returns to Breathe, ready for the next session.
    func showBreathe() {
        tabs?.select(AppTab.breathe)
        if let split { show(.breathe, in: split) }
    }

    /// Shows History after a session: the list with the new session on top on
    /// iPhone; on iPad, that session also opens in the detail column.
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

    /// The iPad sidebar's selection, derived from the content column.
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
