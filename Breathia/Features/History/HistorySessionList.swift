import SwiftUI

/// The recorded sessions as cards, grouped by when they happened, newest first.
/// Swipe a card to delete it, or use its context menu.
struct HistorySessionList: View {
    let usesSelection: Bool
    let selectedSessionID: SessionRecord.ID?
    let onOpen: (SessionRecord.ID) -> Void
    let onDelete: (SessionRecord) -> Void

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
                            // Swipe left to delete; a full swipe deletes at once, as in Mail.
                            .swipeActions {
                                Button("common.delete", systemImage: "trash", role: .destructive) {
                                    onDelete(session)
                                }
                            }
                            .contextMenu {
                                Button("common.delete", systemImage: "trash", role: .destructive) {
                                    onDelete(session)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
        // Lets the cards take swipe actions outside a List.
        .swipeActionsContainer()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HistorySessionList(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDelete: { _ in })
    }
    .environment(PreviewStores.sessionHistory())
}
#endif
