import SwiftUI

/// A bar under the count that fills as you breathe in and empties as you breathe
/// out — the breath's motion in a line, leaving the screen to the count and the cue.
struct WatchBreathMeter: View {
    let position: BreathingClock.Position
    let tint: Color
    /// The smallest and largest scale the technique's phases reach: an empty and a
    /// full bar.
    let scaleRange: (smallest: Double, largest: Double)
    /// Always On: a quieter bar, stepped once a second.
    var isDimmed = false

    private var fill: Double {
        let span = scaleRange.largest - scaleRange.smallest
        // A pattern that never changes scale still shows each phase passing.
        guard span > 0 else { return position.phaseProgress }
        return min(1, max(0, (position.scale - scaleRange.smallest) / span))
    }

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(tint.opacity(0.25))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint.opacity(isDimmed ? 0.6 : 1))
                        // Never narrower than the bar is tall, so an empty bar still
                        // shows where the breath starts.
                        .frame(width: max(proxy.size.height, proxy.size.width * fill))
                }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    WatchBreathMeter(
        position: BreathingClock(technique: TechniqueCatalog.all[1]).position(at: 2),
        tint: TechniqueCatalog.all[1].tint,
        scaleRange: (0.6, 1)
    )
    .frame(width: 140, height: 6)
}
#endif
