import SwiftUI

/// History's session list, wired to the navigator.
struct HistoryList: View {
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        HistoryListView(
            usesSelection: navigator.usesSplitLayout,
            selectedSessionID: navigator.selectedSessionID,
            onOpen: { navigator.sessionID = $0 },
            onDeleted: { id in
                if navigator.sessionID == id {
                    navigator.closeHistorySession()
                }
            },
            onStartSession: { navigator.showBreathe() }
        )
        .environment(screens.sessionHistory)
    }
}
