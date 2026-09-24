import SwiftUI

/// Pause / resume and end, side by side under the session's panel.
struct LiveSessionControls: View {
    let model: BreathingSessionModel

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isRegular: Bool { horizontalSizeClass == .regular }
    #else
    private let isRegular = true
    #endif

    var body: some View {
        HStack(alignment: .top, spacing: isRegular ? 64 : 48) {
            SessionControlButton(
                title: model.isPaused ? "common.resume" : "common.pause",
                systemImage: model.isPaused ? "play.fill" : "pause.fill",
                role: .primary(model.technique.tint),
                diameter: isRegular ? 96 : 84,
                action: model.togglePause
            )
            // Space bar pauses and resumes with a keyboard (iPad).
            .keyboardShortcut(.space, modifiers: [])
            SessionControlButton(
                title: "common.end",
                systemImage: "stop.fill",
                role: .destructive,
                diameter: isRegular ? 96 : 84,
                action: model.end
            )
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.isPaused)
    }
}
