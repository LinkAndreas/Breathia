import SwiftUI

/// The session's controls page: End and Pause / Resume, side by side as in Workout.
struct WatchSessionControls: View {
    let model: BreathingSessionModel
    /// Called after pausing or resuming, to return to the breathing page.
    let onTogglePause: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            WatchSessionControlButton(title: "common.end", systemImage: "xmark", tint: .red, action: model.end)
            WatchSessionControlButton(
                title: model.isPaused ? "common.resume" : "common.pause",
                systemImage: model.isPaused ? "arrow.clockwise" : "pause.fill",
                tint: model.technique.tint
            ) {
                model.togglePause()
                onTogglePause()
            }
        }
        .padding(.horizontal, 8)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchSessionControls(model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]), onTogglePause: {})
    }
}
#endif
