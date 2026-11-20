import SwiftUI

/// Deletes every session from History, after asking.
struct HistorySettingsSection: View {
    @Environment(SessionHistory.self) private var history
    @State private var isConfirmingDeletion = false

    var body: some View {
        Section {
            Button(role: .destructive) {
                isConfirmingDeletion = true
            } label: {
                SettingsLabel("settings.history.deleteAll", systemImage: "trash.fill", tone: .destructive)
                    // The row's label keeps its colors when disabled; dim it so an
                    // empty History reads as nothing to delete.
                    .opacity(history.sessions.isEmpty ? 0.4 : 1)
            }
            .disabled(history.sessions.isEmpty)
            // Attached to the button so the dialog emerges from it.
            .confirmationDialog("settings.history.deleteAllQuestion", isPresented: $isConfirmingDeletion, titleVisibility: .visible) {
                Button("settings.history.deleteAllButton", role: .destructive) {
                    history.deleteAll()
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                #if os(iOS)
                Text("settings.history.deleteAllMessage")
                #else
                // A Mac doesn't save to Apple Health.
                Text("settings.history.deleteAllMessageMac")
                #endif
            }
        } header: {
            Text("history.title")
        } footer: {
            Text("settings.history.footer")
        }
    }
}

#if DEBUG
#Preview {
    Form {
        HistorySettingsSection()
    }
    .environment(PreviewStores.sessionHistory())
}
#endif
