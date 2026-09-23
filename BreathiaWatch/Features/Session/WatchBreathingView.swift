import SwiftUI

/// The live session on Apple Watch: the breathing circle fills the screen, with
/// heart rate and time remaining in the top corners and Pause / End in the
/// system bottom toolbar.
struct WatchBreathingView: View {
    let model: BreathingSessionModel

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var scaleRange: (smallest: Double, largest: Double) {
        let scales = model.technique.phases.map(\.scale)
        return (scales.min() ?? 1, scales.max() ?? 1)
    }

    /// Breaths a full session takes. Shown under the breath number in techniques
    /// whose breaths are too short to count in seconds.
    private var totalBreaths: Int {
        let cycle = model.technique.cycleDuration
        return cycle > 0 ? max(1, Int(model.targetDuration) / cycle) : 1
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            // Always On: hold the circle still instead of animating at a low frame rate.
            TimelineView(.animation(paused: model.isPaused || isLuminanceReduced)) { context in
                WatchBreathingCircle(
                    position: model.position(at: context.date),
                    tint: model.technique.tint,
                    // At its largest the circle just fills the screen.
                    diameter: side * 0.97 / scaleRange.largest,
                    smallestScale: scaleRange.smallest,
                    totalBreaths: totalBreaths
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(model.isPaused ? 0.45 : 1)
            }
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text(heartRateLabel)
                    .monospacedDigit()
            }
            .font(.footnote)
        }
        .overlay(alignment: .topTrailing) {
            Text(Formatters.clock(model.remaining))
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(
                    model.isPaused ? "common.resume" : "common.pause",
                    systemImage: model.isPaused ? "play.fill" : "pause.fill",
                    action: model.togglePause
                )
                Spacer()
                Button("common.end", systemImage: "stop.fill", role: .destructive, action: model.end)
                    .tint(.red)
            }
        }
        .overlay(alignment: .bottom) {
            if model.isPaused {
                Text("watch.session.paused")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: .capsule)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.isPaused)
    }

    private var heartRateLabel: String {
        guard model.isSensorConnected, let heartRate = model.liveHeartRate else { return "--" }
        return "\(heartRate)"
    }
}

private struct WatchBreathingCircle: View {
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
