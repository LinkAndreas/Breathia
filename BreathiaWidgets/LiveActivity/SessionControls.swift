import ActivityKit
import AppIntents
import SwiftUI

/// Pause/Resume and Stop, as round buttons in the technique's colour.
struct SessionControls: View {
    let attributes: BreathingActivityAttributes
    let state: BreathingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 10) {
            if state.isPaused {
                // Opens the app: a session is followed on screen.
                Button(intent: ResumeSessionIntent()) {
                    Image(systemName: "play.fill")
                        .frame(width: 20, height: 20)
                }
                .accessibilityLabel(Text(verbatim: attributes.resumeTitle))
            } else {
                Button(intent: PauseSessionIntent()) {
                    Image(systemName: "pause.fill")
                        .frame(width: 20, height: 20)
                }
                .accessibilityLabel(Text(verbatim: attributes.pauseTitle))
            }

            Button(intent: EndSessionIntent()) {
                Image(systemName: "stop.fill")
                    .frame(width: 20, height: 20)
            }
            .accessibilityLabel(Text(verbatim: attributes.endTitle))
        }
        .font(.system(size: 15, weight: .bold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(attributes.tint)
    }
}
