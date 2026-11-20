import SwiftUI

struct HistoryListView: View {
    /// `true` on iPad and Mac, where the opened session stays highlighted next to
    /// the detail column; `false` on iPhone, where rows push and show a chevron.
    let usesSelection: Bool
    let selectedSessionID: SessionRecord.ID?
    let onOpen: (SessionRecord.ID) -> Void
    let onDeleted: (SessionRecord.ID) -> Void
    /// Leaves the empty History for Breathe, where the first session starts.
    let onStartSession: () -> Void

    @Environment(SessionHistory.self) private var history

    var body: some View {
        Group {
            if history.sessions.isEmpty {
                HistoryEmptyView(onStartSession: onStartSession)
            } else {
                HistorySessionList(
                    usesSelection: usesSelection,
                    selectedSessionID: selectedSessionID,
                    onOpen: onOpen,
                    onDelete: delete
                )
            }
        }
        .background(Theme.Palette.background)
        .navigationTitle("history.title")
        #if os(macOS)
        // A Mac window has one title, taken from this column; the open session's
        // day shows as its subtitle, as the selected mailbox's details do in Mail.
        .navigationSubtitle(selectedSession.map { Formatters.relativeDay($0.date) } ?? "")
        #endif
    }

    #if os(macOS)
    private var selectedSession: SessionRecord? {
        selectedSessionID.flatMap { history.session(withID: $0) }
    }
    #endif

    private func delete(_ session: SessionRecord) {
        history.delete(session)
        onDeleted(session.id)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HistoryListView(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDeleted: { _ in }, onStartSession: {})
    }
    .environment(PreviewStores.sessionHistory())
}
#endif

#if DEBUG
#Preview("Empty") {
    NavigationStack {
        HistoryListView(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDeleted: { _ in }, onStartSession: {})
    }
    .environment(PreviewStores.sessionHistory(sessions: []))
}
#endif
