import SwiftUI

/// The live session screen: status, progress, the breathing circle, biofeedback,
/// and pause / end controls.
struct BreathingSessionView: View {
    let model: BreathingSessionModel

    var body: some View {
        SessionArrangement {
            LiveBreathingCircle(model: model)
        } secondary: {
            SessionPanel(model: model)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview {
    BreathingSessionView(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
