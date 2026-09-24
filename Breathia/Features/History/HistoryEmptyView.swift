import SwiftUI

/// History before the first session: what will appear here, and a way to start
/// the session that fills it.
struct HistoryEmptyView: View {
    let onStartSession: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("history.noSessionsYet", systemImage: "clock")
        } description: {
            Text("history.completedBreathingSessions")
        } actions: {
            Button("history.startASession", systemImage: "wind", action: onStartSession)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        }
        // Fill the column, so the message sits in its middle rather than under the title.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HistoryEmptyView {}
            .navigationTitle("history.title")
    }
}
#endif
