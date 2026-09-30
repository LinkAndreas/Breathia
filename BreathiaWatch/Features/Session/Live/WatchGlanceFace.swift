import SwiftUI

/// The session in Always On when the watch redraws only about once a minute: nothing
/// here can go stale in that time, so there is no count and no phase — the taps
/// carry the breath.
struct WatchGlanceFace: View {
    let model: BreathingSessionModel

    /// Whole minutes left, rounded up, so the last minute still reads "1 min".
    private var minutesLeft: Int {
        max(1, Int((model.remaining / 60).rounded(.up)))
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(model.technique.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if model.isPaused {
                Text("watch.session.paused")
                    .font(.footnote.weight(.semibold))
            } else {
                Text("watch.session.minutesLeft \(minutesLeft)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Label("watch.session.followTheTaps", systemImage: "hand.tap")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    WatchGlanceFace(model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
