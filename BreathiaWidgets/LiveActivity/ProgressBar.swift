import ActivityKit
import SwiftUI

/// How far the session is: filling by itself while running, frozen while paused.
struct ProgressBar: View {
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
