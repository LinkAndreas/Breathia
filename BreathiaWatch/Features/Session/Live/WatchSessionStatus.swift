import SwiftUI

/// The session at a glance, beside the clock: heart rate and time remaining.
struct WatchSessionStatus: View {
    let model: BreathingSessionModel
    /// Time left in the session, read at the moment the face is drawn.
    let remaining: TimeInterval

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text(heartRateLabel)
            }
            Text(Formatters.clock(remaining))
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
        .monospacedDigit()
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heartRateLabel: String {
        guard model.isSensorConnected, let heartRate = model.liveHeartRate else { return "--" }
        return "\(heartRate)"
    }
}

#if DEBUG
#Preview {
    WatchSessionStatus(model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]), remaining: 300)
}
#endif
