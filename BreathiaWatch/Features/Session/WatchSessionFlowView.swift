import SwiftUI

/// Root of the full-screen session cover on Apple Watch: countdown → session →
/// summary. `WatchSessionRunner` runs the session and the workout alongside it.
struct WatchSessionFlowView: View {
    let technique: Technique
    let runner: WatchSessionRunner
    /// Leaves without a result (cancelled during the countdown).
    let onCancel: () -> Void
    /// Leaves the summary.
    let onDone: () -> Void

    @State private var session: BreathingSessionModel?

    var body: some View {
        NavigationStack {
            if let session {
                WatchSessionStageView(
                    session: session,
                    technique: technique,
                    runner: runner,
                    onCancel: onCancel,
                    onDone: onDone
                )
                .animation(.smooth, value: session.stage)
            }
        }
        .onAppear {
            if session == nil {
                session = runner.start(technique)
            }
        }
        .onDisappear {
            if let session { runner.close(session) }
        }
        .onChange(of: session?.stage) { _, stage in
            guard case .completed? = stage, let session else { return }
            runner.complete(session)
        }
    }
}
