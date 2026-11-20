import Foundation

/// A section's detail page: pushed onto the section's stack in the tab bar, shown
/// in the detail column of the split view.
nonisolated enum AppDetail: Hashable {
    /// A technique's explanations and its Start button.
    case technique(Technique.ID)
    /// A recorded session.
    case session(SessionRecord.ID)
    /// History's detail column before a session is chosen.
    case noSession
    /// A settings category or info page.
    case settings(SettingsPage)
}

extension AppNavigator {
    /// The page pushed onto `tab`'s stack in the tab bar, if any.
    func pushedDetail(in tab: AppTab) -> AppDetail? {
        switch tab {
        case .breathe: techniqueID.map(AppDetail.technique)
        case .history: sessionID.map(AppDetail.session)
        case .settings: settingsPage.map(AppDetail.settings)
        }
    }

    /// Opens `detail` in `tab`, or goes back to the list with `nil`.
    func setPushedDetail(_ detail: AppDetail?, in tab: AppTab) {
        switch tab {
        case .breathe:
            if case let .technique(id)? = detail { techniqueID = id } else { techniqueID = nil }
        case .history:
            if case let .session(id)? = detail { sessionID = id } else { sessionID = nil }
        case .settings:
            if case let .settings(page)? = detail { settingsPage = page } else { settingsPage = nil }
        }
    }

    /// What `tab`'s detail column shows in the split view, which is never empty.
    func columnDetail(in tab: AppTab) -> AppDetail {
        switch tab {
        case .breathe: .technique(techniqueID ?? TechniqueCatalog.defaultTechniqueID)
        case .history: sessionID.map(AppDetail.session) ?? .noSession
        case .settings: .settings(settingsPage ?? .sensor)
        }
    }
}

extension AppDetail {
    /// Gives a technique page and its floating Start button the whole screen on
    /// iPhone.
    var hidesTabBar: Bool {
        if case .technique = self { true } else { false }
    }
}
