import ActivityKit
import SwiftUI
import WidgetKit

/// Name and controls on top, then the progress bar with elapsed and total time.
/// The small family (Smart Stack, CarPlay) leaves out the controls.
struct ActivityContentView: View {
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
