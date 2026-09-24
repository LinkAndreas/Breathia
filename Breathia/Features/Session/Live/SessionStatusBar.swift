import SwiftUI

/// The technique as the screen's headline, with the sensor's state beside it.
struct SessionStatusBar: View {
    let model: BreathingSessionModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(model.technique.name)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                StatusDot(isActive: model.isSensorConnected)
                Text(heartRateLabel)
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(model.isSensorConnected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Palette.elevated, in: .capsule)
        }
    }

    private var heartRateLabel: String {
        guard model.isSensorConnected else { return String(localized: "session.noSensor") }
        return model.liveHeartRate.map { String(localized: "common.bpm \($0)") } ?? "—"
    }
}

#if DEBUG
#Preview {
    SessionStatusBar(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
        .padding()
}
#endif
