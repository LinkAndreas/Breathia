import ActivityKit
import SwiftUI

/// The progress bar, with elapsed time under its start and the total under its end.
struct SessionProgress: View {
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
