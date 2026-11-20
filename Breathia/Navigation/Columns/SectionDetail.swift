import SwiftUI

/// A section's detail page: pushed in the tab bar, the detail column in the split view.
struct SectionDetail: View {
    let detail: AppDetail
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        switch detail {
        case let .technique(id):
            TechniqueDetailView(technique: TechniqueCatalog.technique(withID: id)) {
                navigator.startSession(with: $0)
            }
            .id(id)

        case let .session(id):
            HistoryDetailView(sessionID: id) { session in
                // The page already confirmed the deletion: leave it, then delete.
                navigator.closeHistorySession()
                screens.sessionHistory.delete(session)
            }
            .id(id)
            .environment(screens.sessionHistory)

        case .noSession:
            ContentUnavailableView(
                "history.noSelection.selectASession",
                systemImage: "clock",
                description: Text("history.noSelection.chooseASession")
            )

        case let .settings(page):
            SettingsPageDestination(
                page: page,
                heartRateMonitor: screens.heartRateMonitor,
                settingsStore: screens.settingsStore,
                mindfulMinutes: screens.mindfulMinutes,
                appIconStore: screens.appIconStore,
                sessionHistory: screens.sessionHistory
            )
            .environment(\.auditionCue, screens.auditionCue)
        }
    }
}
