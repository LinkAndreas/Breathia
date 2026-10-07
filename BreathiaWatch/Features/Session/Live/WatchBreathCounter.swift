import SwiftUI

/// The session's big number on Apple Watch: seconds left in the breath, or — where
/// they'd never change — which breath this is, with "of 60" under it.
struct WatchBreathCounter: View {
    let position: BreathingClock.Position
    /// Breaths in the whole session — the "of 60" under a breath number.
    let totalBreaths: Int
    /// The height the number may use.
    let height: CGFloat
    /// Always On: the number changes in place, once a second, without animating.
    var isDimmed = false

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
        VStack(spacing: 0) {
            // Quieter during a hold, where the meter stands still. The breath number
            // gives up a little size to the "of N" underneath it.
            Text(position.readout.value, format: .number)
                .font(.system(size: height * (countsBreaths ? 0.7 : 0.92), weight: .semibold, design: .rounded))
                .foregroundStyle(isHolding ? .secondary : .primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(isDimmed ? .identity : .numericText(countsDown: position.readout.countsDown))
                .animation(isDimmed ? nil : .snappy(duration: 0.25), value: position.readout.value)
            if countsBreaths {
                Text("session.breathOf \(totalBreaths)")
                    .font(.system(size: height * 0.13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
#Preview {
    WatchBreathCounter(
        position: BreathingClock(technique: TechniqueCatalog.all[1]).position(at: 2),
        totalBreaths: 60,
        height: 120
    )
}
#endif
