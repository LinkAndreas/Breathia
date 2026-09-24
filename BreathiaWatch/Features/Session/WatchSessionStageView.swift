import SwiftUI

/// The session's current stage on Apple Watch: the countdown, the session, or its summary.
struct WatchSessionStageView: View {
    let session: BreathingSessionModel
    let technique: Technique
    let runner: WatchSessionRunner
    /// Leaves without a result (cancelled during the countdown).
    let onCancel: () -> Void
    /// Leaves the summary.
    let onDone: () -> Void

    var body: some View {
        switch session.stage {
        case let .countdown(value):
            WatchCountdownView(value: value, technique: technique)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common.cancel", systemImage: "xmark") {
                            runner.close(session)
                            onCancel()
                        }
                    }
                }
        case .running:
            WatchBreathingView(model: session)
        case let .completed(record):
            WatchSessionSummaryView(session: record, wasRecorded: session.wasRecorded, onDone: onDone)
        }
    }
}
