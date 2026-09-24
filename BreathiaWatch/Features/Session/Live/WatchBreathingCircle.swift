import SwiftUI

struct WatchBreathingCircle: View {
    let position: BreathingClock.Position
    let tint: Color
    let diameter: CGFloat
    /// The smallest scale the circle reaches in this technique (end of an exhale).
    /// The label is fitted inside the circle at that size, so it never crowds the ring.
    let smallestScale: Double
    /// Breaths in the whole session — the "of 60" under a breath number.
    let totalBreaths: Int

    /// Side of the square the label may use: the square inscribed in the smallest
    /// circle (≈ 0.71 × its diameter), shrunk a little to keep a margin to the ring.
    private var labelSide: CGFloat { diameter * smallestScale * 0.62 }


    private var isHolding: Bool { position.phase.kind == .hold }

    private var countsBreaths: Bool {
        if case .breathNumber = position.readout { true } else { false }
    }

    private var accessibilityLabel: LocalizedStringKey {
        switch position.readout {
        case .secondsLeft:
            "watch.session.phaseAccessibilityLabel \(position.phase.kind.title) \(position.secondsRemaining)"
        case let .breathNumber(breath):
            "watch.session.breathAccessibilityLabel \(position.phase.kind.title) \(breath) \(totalBreaths)"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
                .overlay {
                    // While the circle is still, its ring drains with the hold.
                    if isHolding {
                        Circle()
                            .strokeBorder(tint.opacity(0.3), lineWidth: 2)
                        Circle()
                            .inset(by: 1.25)
                            .trim(from: 0, to: 1 - position.phaseProgress)
                            .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    } else {
                        Circle()
                            .strokeBorder(tint, lineWidth: 2)
                    }
                }
                .frame(width: diameter, height: diameter)
                .scaleEffect(position.scale)

            VStack(spacing: labelSide * 0.03) {
                Text(position.phase.kind.title)
                    .textCase(.uppercase)
                    .font(.system(size: labelSide * 0.21, weight: .semibold, design: .rounded))
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                // Seconds left in the breath, or — where they'd never change — which
                // breath this is. Quieter during a hold, where the draining ring
                // already shows the time left. The breath number gives up a little
                // size to the "of N" underneath it.
                Text(position.readout.value, format: .number)
                    .font(.system(size: labelSide * (countsBreaths ? 0.44 : 0.56), weight: .light, design: .rounded))
                    .foregroundStyle(isHolding ? .secondary : .primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: position.readout.countsDown))
                    .animation(.snappy, value: position.readout.value)
                if countsBreaths {
                    Text("session.breathOf \(totalBreaths)")
                        .font(.system(size: labelSide * 0.14))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: labelSide, height: labelSide)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
#Preview {
    WatchBreathingCircle(position: BreathingClock(technique: TechniqueCatalog.all[1]).position(at: 2), tint: TechniqueCatalog.all[1].tint, diameter: 150, smallestScale: 0.6, totalBreaths: 60)
}
#endif
