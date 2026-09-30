import SwiftUI

/// The current phase — inhale, hold, exhale — named above the circle.
struct WatchPhaseTitle: View {
    let phase: BreathPhase

    var body: some View {
        Text(phase.kind.title)
            .textCase(.uppercase)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .tracking(0.8)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: phase.kind)
    }
}

#if DEBUG
#Preview {
    WatchPhaseTitle(phase: .inhale(4))
}
#endif
