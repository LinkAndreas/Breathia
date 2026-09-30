import ActivityKit
import SwiftUI

/// Time elapsed in the session: counting up by itself while running, frozen while
/// paused. Its live text takes all the width it's offered, so callers limit
/// its frame.
struct ElapsedTime: View {
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
