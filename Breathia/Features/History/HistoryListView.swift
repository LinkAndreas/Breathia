import SwiftUI

struct HistoryListView: View {
    /// `true` on iPad and Mac, where the opened session stays highlighted next to
    /// the detail column; `false` on iPhone, where rows push and show a chevron.
    let usesSelection: Bool
    let selectedSessionID: SessionRecord.ID?
    let onOpen: (SessionRecord.ID) -> Void
    let onDeleted: (SessionRecord.ID) -> Void

    @Environment(SessionHistory.self) private var history

    var body: some View {
        ScrollView {
            // Laid out like the techniques in Breathe: cards grouped under headers,
            // here by when the sessions happened, newest first.
            VStack(spacing: 0) {
                ForEach(SessionGroup.grouping(history.sessions)) { group in
                    CardListHeader {
                        Text(group.period.title())
                    }
                    LazyVStack(spacing: 10) {
                        ForEach(group.sessions) { session in
                            HistoryRow(
                                session: session,
                                period: group.period,
                                isSelected: usesSelection && session.id == selectedSessionID,
                                showsDisclosure: !usesSelection
                            ) {
                                onOpen(session.id)
                            }
                            .contextMenu {
                                Button("common.delete", systemImage: "trash", role: .destructive) {
                                    delete(session)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Theme.Palette.background)
        .overlay {
            if history.sessions.isEmpty {
                ContentUnavailableView(
                    "history.noSessionsYet",
                    systemImage: "clock",
                    description: Text("history.completedBreathingSessions")
                )
            }
        }
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
        HistoryListView(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDeleted: { _ in })
    }
    .environment(PreviewStores.sessionHistory())
}
#endif

#if DEBUG
#Preview("Empty") {
    NavigationStack {
        HistoryListView(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDeleted: { _ in })
    }
    .environment(PreviewStores.sessionHistory(sessions: []))
}
#endif
