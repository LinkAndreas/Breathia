import SwiftUI

/// Everything but the circle, in the pane beside or below it: one group, centred
/// on the circle, so nothing is stranded at the pane's top or bottom edge.
struct SessionPanel: View {
    let model: BreathingSessionModel
    /// Condensed for a short screen: tighter spacing and smaller controls, leaving
    /// the height to the circle.
    var isCompact = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: isCompact ? 8 : 24)
            SessionStatusHeader(model: model)
            BiofeedbackPill(model: model)
                .padding(.top, isCompact ? 14 : 40)
                .padding(.bottom, 14)
            LiveMetrics(model: model)
            LiveSessionControls(model: model, isCompact: isCompact)
                .padding(.top, 4)
            Spacer(minLength: isCompact ? 8 : 24)
        }
    }
}

#if DEBUG
#Preview {
    SessionPanel(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
