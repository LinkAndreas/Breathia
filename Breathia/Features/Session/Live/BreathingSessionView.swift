import SwiftUI

/// The live session screen: status, progress, the breathing circle, biofeedback,
/// and pause / end controls.
struct BreathingSessionView: View {
    let model: BreathingSessionModel

    /// Below this height the panel is condensed, so the circle keeps its room on a
    /// short screen — iPhone Duo's outer display, a phone on its side, a small window.
    private static let compactPanelHeight: CGFloat = 720

    var body: some View {
        GeometryReader { proxy in
            SessionArrangement {
                LiveBreathingCircle(model: model)
            } secondary: {
                SessionPanel(model: model, isCompact: proxy.size.height < Self.compactPanelHeight)
                    .frame(maxWidth: 440)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#if DEBUG
#Preview {
    BreathingSessionView(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
