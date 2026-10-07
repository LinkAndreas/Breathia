import SwiftUI

/// The current phase — inhale, hold, exhale — named above the count.
struct WatchPhaseTitle: View {
    let phase: BreathPhase
    let tint: Color
    /// Always On: the name changes in place, without fading.
    var isDimmed = false

    var body: some View {
        Text(phase.kind.title)
            .textCase(.uppercase)
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .contentTransition(.opacity)
            .animation(isDimmed ? nil : .easeInOut(duration: 0.3), value: phase.kind)
    }
}

#if DEBUG
#Preview {
    WatchPhaseTitle(phase: .inhale(4), tint: TechniqueCatalog.all[1].tint)
}
#endif
