import SwiftUI

/// The countdown's seconds in a ring that drains as they pass.
struct CountdownRing: View {
    let value: Int
    /// When the countdown began; the ring drains continuously from there, and stays
    /// full while it's `nil` (waiting to start again after the user left the app).
    let startedAt: Date?
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.10))
            // Thin like the live session's circle.
            Circle()
                .stroke(tint.opacity(0.25), lineWidth: 2)
            // Drawn from the clock rather than animated: an animation starting as
            // the screen appears would also animate its first layout, which slides
            // a Mac sheet's content in from the top-left corner.
            TimelineView(.animation(paused: reduceMotion)) { context in
                Circle()
                    .trim(from: 0, to: ringProgress(at: context.date))
                    .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(value, format: .number)
                .font(.system(size: 104, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: value)
        }
        .frame(width: 220, height: 220)
        .background {
            // Centred on the ring and wider than it, so the tint wash reaches past
            // its pane.
            RadialGradient(
                colors: [tint.opacity(0.16), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 380
            )
            .frame(width: 760, height: 760)
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(value, format: .number))
    }

    /// How much of the ring is left, running out as the session begins. Measured from
    /// one start time, so it drains evenly without a jump as each second ticks over.
    /// With Reduce Motion it steps down once per second instead.
    private func ringProgress(at date: Date) -> Double {
        let length = Double(BreathingSessionModel.countdownStart)
        guard let startedAt else { return 1 }
        guard !reduceMotion else { return Double(value - 1) / length }
        return max(0, 1 - date.timeIntervalSince(startedAt) / length)
    }
}

#if DEBUG
#Preview {
    CountdownRing(value: 3, startedAt: .now, tint: TechniqueCatalog.all[1].tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
#endif
