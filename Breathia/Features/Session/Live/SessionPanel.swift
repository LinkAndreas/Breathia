import SwiftUI

/// Everything but the circle, in the pane beside or below it: one group, centred
/// on the circle, so nothing is stranded at the pane's top or bottom edge.
struct SessionPanel: View {
    let model: BreathingSessionModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            SessionStatusHeader(model: model)
            BiofeedbackPill(model: model)
                .padding(.top, 40)
                .padding(.bottom, 14)
            LiveMetrics(model: model)
            LiveSessionControls(model: model)
                .padding(.top, 4)
            Spacer(minLength: 24)
        }
    }
}
