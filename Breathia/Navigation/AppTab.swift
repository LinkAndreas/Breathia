import NavigationKit

/// The app's top-level sections: the tabs in a narrow window, the sidebar items in a wide one.
enum AppTab: CaseIterable, Hashable {
    case breathe
    case history
    case settings

    /// The title's localization key. NavigationKit's tab bar resolves it through
    /// `LocalizedStringKey` at runtime, so the compiler can't extract it — these
    /// keys are maintained by hand in the string catalog.
    var titleKey: String {
        switch self {
        case .breathe: "tab.breathe"
        case .history: "tab.history"
        case .settings: "tab.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .breathe: "wind"
        case .history: "clock"
        case .settings: "gearshape"
        }
    }

    /// The stack this section's tab starts with.
    func makeTabNavigator() -> StackNavigator {
        switch self {
        case .breathe: StackNavigator(root: BreatheRoute.home)
        case .history: StackNavigator(root: HistoryRoute.list)
        case .settings: StackNavigator(root: SettingsRoute.form)
        }
    }
}

extension AppTab: Identifiable {
    var id: Self { self }
}
