import Foundation

/// The app's top-level sections: the tabs in a narrow window, the sidebar items in a wide one.
nonisolated enum AppTab: CaseIterable, Hashable, Sendable {
    case breathe
    case history
    case settings

    var title: LocalizedStringResource {
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
}
