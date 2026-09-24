import SwiftUI

struct BreathingCircle: View {
    let position: BreathingClock.Position
    let tint: Color
    let diameter: CGFloat
    /// The smallest scale the circle reaches in this technique. The label is fitted
    /// inside the circle at that size, so it never crowds the ring.
    let smallestScale: Double
    /// Breaths in the whole session — the "of 60" under a breath number.
    let totalBreaths: Int


    /// The square the label may use: well inside the square inscribed in the
    /// smallest circle (≈ 0.71 × its diameter), leaving generous room to the ring.
    private var labelSide: CGFloat { diameter * smallestScale * 0.56 }

    private var isHolding: Bool { position.phase.kind == .hold }

    private var accessibilityLabel: LocalizedStringKey {
        switch position.readout {
        case .secondsLeft:
            "session.phaseAccessibilityLabel \(position.phase.kind.title) \(position.secondsRemaining) \(position.cycle)"
        case let .breathNumber(breath):
            "session.breathAccessibilityLabel \(position.phase.kind.title) \(breath) \(totalBreaths)"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.12))
                .overlay {
                    // While the circle is still, its ring drains with the hold.
                    if isHolding {
                        Circle()
                            .strokeBorder(tint.opacity(0.25), lineWidth: 1.5)
                        Circle()
                            .inset(by: 1)
                            .trim(from: 0, to: 1 - position.phaseProgress)
                            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    } else {
                        Circle()
                            .strokeBorder(tint, lineWidth: 1.5)
                    }
                }
                .frame(width: diameter, height: diameter)
                .scaleEffect(position.scale)

            VStack(spacing: labelSide * 0.02) {
                Text(position.phase.kind.title)
                    .textCase(.uppercase)
                    .font(.system(size: labelSide * 0.15, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                // Seconds left in the breath, or — where they'd never change — which
                // breath this is. Quieter during a hold, where the draining ring
                // already shows the time left.
                Text(position.readout.value, format: .number)
                    .font(.system(size: labelSide * 0.5, weight: isHolding ? .regular : .semibold, design: .rounded))
                    .foregroundStyle(isHolding ? .secondary : .primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: position.readout.countsDown))
                    .animation(.snappy, value: position.readout.value)
                BreathingCircleCaption(position: position, totalBreaths: totalBreaths)
                    .font(.system(size: labelSide * 0.1))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .frame(width: labelSide, height: labelSide)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
#Preview {
    BreathingCircle(position: BreathingClock(technique: TechniqueCatalog.all[1]).position(at: 2), tint: TechniqueCatalog.all[1].tint, diameter: 280, smallestScale: 0.6, totalBreaths: 60)
        .frame(width: 320, height: 320)
}
#endif
