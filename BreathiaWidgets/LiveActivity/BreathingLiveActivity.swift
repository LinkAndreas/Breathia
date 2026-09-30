import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// A running breathing session on the Lock Screen, in the Dynamic Island, and in
/// Apple Watch's Smart Stack: the technique's name, the session's progress with
/// elapsed and total time, and buttons to pause or stop it.
///
/// The progress bar and elapsed time move by themselves from the session's end
/// date, so the activity stays correct while the app is suspended. The buttons run
/// intents in the app's process, which act on the running session.
struct BreathingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreathingActivityAttributes.self) { context in
            ActivityContentView(attributes: context.attributes, state: context.state)
                .activitySystemActionForegroundColor(context.attributes.tint)
        } dynamicIsland: { context in
            let attributes = context.attributes
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(verbatim: attributes.techniqueName)
                        .font(.headline)
                        .foregroundStyle(attributes.tint)
                        .lineLimit(1)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SessionControls(attributes: attributes, state: state)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SessionProgress(attributes: attributes, state: state)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: state.isPaused ? "pause.fill" : "wind")
                    .foregroundStyle(attributes.tint)
            } compactTrailing: {
                // As wide as four digits need, or as the island allows: iPhone Duo's
                // upright island is narrower than that, and the time shrinks to fit
                // rather than losing its first digit.
                ElapsedTime(attributes: attributes, state: state)
                    .foregroundStyle(attributes.tint)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: 42)
            } minimal: {
                Image(systemName: state.isPaused ? "pause.fill" : "wind")
                    .foregroundStyle(attributes.tint)
            }
            .keylineTint(attributes.tint)
        }
        // The same content, sized for the Smart Stack on Apple Watch and for CarPlay.
        .supplementalActivityFamilies([.small])
    }
}

// MARK: Previews

private extension BreathingActivityAttributes {
    static let preview = BreathingActivityAttributes(
        techniqueName: "Box Breathing",
        sessionDuration: 300,
        tintRed: 0.62,
        tintGreen: 0.16,
        tintBlue: 0.12,
        pauseTitle: "Pause",
        resumeTitle: "Resume",
        endTitle: "End"
    )
}

private extension BreathingActivityAttributes.ContentState {
    static var running: Self {
        Self(sessionEndDate: .now.addingTimeInterval(210), remaining: 210, isPaused: false)
    }

    static var paused: Self {
        Self(sessionEndDate: .now.addingTimeInterval(160), remaining: 160, isPaused: true)
    }
}

#if DEBUG
#Preview("Lock Screen", as: .content, using: BreathingActivityAttributes.preview) {
    BreathingLiveActivity()
} contentStates: {
    BreathingActivityAttributes.ContentState.running
    BreathingActivityAttributes.ContentState.paused
}
#endif

#if DEBUG
#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: BreathingActivityAttributes.preview) {
    BreathingLiveActivity()
} contentStates: {
    BreathingActivityAttributes.ContentState.running
}
#endif

#if DEBUG
#Preview("Compact", as: .dynamicIsland(.compact), using: BreathingActivityAttributes.preview) {
    BreathingLiveActivity()
} contentStates: {
    BreathingActivityAttributes.ContentState.running
}
#endif
