import SwiftUI

/// The session's current stage: the countdown, the session itself, or its results.
struct SessionStageView: View {
    let model: BreathingSessionModel
    /// Leaves without a result (cancelled during the countdown).
    let onCancel: () -> Void
    /// Leaves the results screen, passing the session if it was recorded.
    let onFinish: (SessionRecord?) -> Void

    var body: some View {
        switch model.stage {
        case let .countdown(value):
            SessionCountdownView(value: value, startedAt: model.countdownStartedAt, technique: model.technique) {
                model.cancel()
                onCancel()
            }
            .transition(.opacity)
        case .running:
            BreathingSessionView(model: model)
                .transition(.opacity)
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        case let .completed(record):
            SessionResultsView(session: record) {
                onFinish(model.wasRecorded ? record : nil)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}
