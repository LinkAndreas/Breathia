import SwiftUI

struct HistoryDetailView: View {
    let sessionID: SessionRecord.ID
    /// Called once the user has confirmed the deletion.
    let onDelete: (SessionRecord) -> Void

    @Environment(SessionHistory.self) private var history
    @State private var isConfirmingDeletion = false

    var body: some View {
        if let session = history.session(withID: sessionID) {
            SessionReportPage(session: session) {
                HistorySessionHeader(technique: session.technique, subtitle: Formatters.clock(session.duration))
            }
            .background(Theme.Palette.background)
            .navigationTitle(Formatters.relativeDay(session.date))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("common.delete", systemImage: "trash", role: .destructive) {
                        isConfirmingDeletion = true
                    }
                    // Attached to the button so the dialog emerges from it, as in
                    // Apple's apps, rather than from the whole screen.
                    .confirmationDialog("history.detail.deleteThisSession", isPresented: $isConfirmingDeletion, titleVisibility: .visible) {
                        Button("history.detail.deleteSession", role: .destructive) {
                            onDelete(session)
                        }
                        Button("common.cancel", role: .cancel) {}
                    }
                }
            }
        } else {
            ContentUnavailableView("history.detail.sessionNotFound", systemImage: "clock.badge.questionmark")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HistoryDetailView(sessionID: PreviewData.sessions[0].id, onDelete: { _ in })
    }
    .environment(PreviewStores.sessionHistory())
}
#endif
