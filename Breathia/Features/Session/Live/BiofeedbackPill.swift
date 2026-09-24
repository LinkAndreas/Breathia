import SwiftUI

/// The biofeedback's verdict while a sensor is connected, or why there is none.
struct BiofeedbackPill: View {
    let model: BreathingSessionModel

    var body: some View {
        if model.isSensorConnected {
            let feedback = model.feedback
            let color = color(for: feedback)
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(feedback.title).font(.subheadline)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Theme.Palette.elevated, in: .capsule)
            .animation(.default, value: feedback)
        } else {
            Text("session.noSensorBiofeedbackUnavailable")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.Palette.elevated, in: .capsule)
        }
    }

    private func color(for feedback: BiofeedbackAnalyzer.Feedback) -> Color {
        switch feedback {
        case .increasing: .green
        case .synchronized: model.technique.tint
        case .collecting, .settling, .stable: .secondary
        }
    }
}

#if DEBUG
#Preview {
    BiofeedbackPill(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
        .padding()
}
#endif
