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
                stageView(for: session)
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

    @ViewBuilder
    private func stageView(for session: BreathingSessionModel) -> some View {
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

private struct WatchCountdownView: View {
    let value: Int
    let technique: Technique

    var body: some View {
        VStack(spacing: 4) {
            Text("common.getReady")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: value)
            Text(technique.name)
                .font(.footnote)
                .foregroundStyle(technique.tint)
                .lineLimit(1)
        }
    }
}
