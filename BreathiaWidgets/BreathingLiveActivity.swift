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
                ElapsedTime(attributes: attributes, state: state)
                    .foregroundStyle(attributes.tint)
                    .frame(width: 42)
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

/// Name and controls on top, then the progress bar with elapsed and total time.
/// The small family (Smart Stack, CarPlay) leaves out the controls.
private struct ActivityContentView: View {
    let attributes: BreathingActivityAttributes
    let state: BreathingActivityAttributes.ContentState

    @Environment(\.activityFamily) private var family

    private var isSmall: Bool {
        if case .small = family { true } else { false }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 6 : 10) {
            HStack(spacing: 12) {
                Text(verbatim: attributes.techniqueName)
                    .font(isSmall ? .headline : .title3.weight(.semibold))
                    .foregroundStyle(attributes.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                if !isSmall {
                    SessionControls(attributes: attributes, state: state)
                }
            }
            SessionProgress(attributes: attributes, state: state)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isSmall ? 12 : 18)
    }
}

/// Pause/Resume and Stop, as round buttons in the technique's colour.
private struct SessionControls: View {
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

/// The progress bar, with elapsed time under its start and the total under its end.
private struct SessionProgress: View {
    let attributes: BreathingActivityAttributes
    let state: BreathingActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 5) {
            ProgressBar(attributes: attributes, state: state)
            HStack {
                ElapsedTime(attributes: attributes, state: state)
                    .frame(width: 60, alignment: .leading)
                Spacer()
                Text(verbatim: Self.clock(attributes.sessionDuration))
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }

    static func clock(_ seconds: TimeInterval) -> String {
        Duration.seconds(Int(max(0, seconds))).formatted(.time(pattern: .minuteSecond))
    }
}

/// How far the session is: filling by itself while running, frozen while paused.
private struct ProgressBar: View {
    let attributes: BreathingActivityAttributes
    let state: BreathingActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isPaused {
                ProgressView(value: pausedFraction)
            } else {
                ProgressView(
                    timerInterval: attributes.sessionRange(endingAt: state.sessionEndDate),
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
            }
        }
        .progressViewStyle(.linear)
        .tint(attributes.tint)
    }

    private var pausedFraction: Double {
        guard attributes.sessionDuration > 0 else { return 0 }
        return min(1, max(0, 1 - state.remaining / attributes.sessionDuration))
    }
}

/// Time elapsed in the session: counting up by itself while running, frozen while
/// paused. Its live text takes all the width it's offered, so callers give it a
/// fixed frame.
private struct ElapsedTime: View {
    let attributes: BreathingActivityAttributes
    let state: BreathingActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isPaused {
                Text(verbatim: SessionProgress.clock(attributes.sessionDuration - state.remaining))
            } else {
                Text(timerInterval: attributes.sessionRange(endingAt: state.sessionEndDate), countsDown: false)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
    }
}

private extension BreathingActivityAttributes {
    var tint: Color {
        Color(.sRGBLinear, red: tintRed, green: tintGreen, blue: tintBlue)
    }

    /// The whole session's time range, given when it ends.
    func sessionRange(endingAt end: Date) -> ClosedRange<Date> {
        min(end.addingTimeInterval(-sessionDuration), end)...end
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
