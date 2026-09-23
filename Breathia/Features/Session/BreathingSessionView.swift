import SwiftUI

/// The live session screen: status, progress, the breathing circle, biofeedback,
/// and pause / end controls.
struct BreathingSessionView: View {
    let model: BreathingSessionModel

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isRegular: Bool { horizontalSizeClass == .regular }
    #else
    private let isRegular = true
    #endif

    private var tint: Color { model.technique.tint }
    /// The circle's limit in its pane.
    private static let maximumCircleDiameter: CGFloat = 640
    /// The smallest the circle gets in this technique (the end of an exhale).
    private var smallestScale: Double { model.technique.phases.map(\.scale).min() ?? 1 }
    /// Breaths a full session takes. Shown under the breath number in techniques
    /// whose breaths are too short to count in seconds.
    private var totalBreaths: Int {
        let cycle = model.technique.cycleDuration
        return cycle > 0 ? max(1, Int(model.targetDuration) / cycle) : 1
    }

    var body: some View {
        SessionArrangement {
            breathingCircle
        } secondary: {
            panel
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
        }
    }

    /// Everything but the circle, in the pane beside or below it: one group, centred
    /// on the circle, so nothing is stranded at the pane's top or bottom edge.
    private var panel: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            header
            feedbackPill
                .padding(.top, 40)
                .padding(.bottom, 14)
            metrics
            controls
                .padding(.top, 4)
            Spacer(minLength: 24)
        }
    }

    // MARK: Parts

    private var header: some View {
        VStack(spacing: 0) {
            statusBar
                .padding(.horizontal, 24)
                // Clear of the display's rounded corner where the status bar runs down
                // the side and the safe area adds nothing at the top.
                .padding(.top, 16)

            progress
                .padding(.horizontal, 24)
                .padding(.top, 14)
        }
    }

    private var breathingCircle: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: model.isPaused)) { context in
                BreathingCircle(
                    position: model.position(at: context.date),
                    tint: tint,
                    diameter: min(Self.maximumCircleDiameter, min(proxy.size.width, proxy.size.height) / 1.2),
                    smallestScale: smallestScale,
                    totalBreaths: totalBreaths
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    /// Live heart rate and HRV, while a sensor is connected.
    @ViewBuilder
    private var metrics: some View {
        if model.isSensorConnected {
            VStack(spacing: 14) {
                LiveMetricCard(
                    value: average(of: model.recentHeartRates).map { String(localized: "session.bpmAvg \($0)") } ?? "—",
                    label: "common.heartRate",
                    values: model.recentHeartRates,
                    tint: tint
                )
                LiveMetricCard(
                    value: average(of: model.recentHRV).map { String(localized: "session.msAvg \($0)") } ?? "—",
                    label: "session.hrv \(model.hrvMetric.title)",
                    values: model.recentHRV,
                    tint: .green
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    /// The technique as the screen's headline, with the sensor's state beside it.
    private var statusBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(model.technique.name)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                StatusDot(isActive: model.isSensorConnected)
                Text(heartRateLabel)
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(model.isSensorConnected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Palette.elevated, in: .capsule)
        }
    }

    private var heartRateLabel: String {
        guard model.isSensorConnected else { return String(localized: "session.noSensor") }
        return model.liveHeartRate.map { String(localized: "common.bpm \($0)") } ?? "—"
    }

    /// A thick bar in the technique's colour, with the elapsed time under its start
    /// and the total under its end.
    private var progress: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(tint.opacity(0.18))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(tint)
                            .frame(width: proxy.size.width * model.progress)
                    }
                }
                .animation(.linear(duration: 0.2), value: model.progress)
            HStack {
                Text(verbatim: Formatters.clock(model.elapsed))
                Spacer()
                Text(verbatim: Formatters.clock(model.targetDuration))
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(Formatters.clock(model.elapsed)) / \(Formatters.clock(model.targetDuration))"))
    }

    @ViewBuilder
    private var feedbackPill: some View {
        if model.isSensorConnected {
            let feedback = model.feedback
            let color = color(for: feedback)
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(feedback.title).font(.subheadline)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Theme.Palette.elevated, in: .capsule)
            .animation(.default, value: feedback)
        } else {
            Text("session.noSensorBiofeedbackUnavailable")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.Palette.elevated, in: .capsule)
        }
    }

    private var controls: some View {
        HStack(alignment: .top, spacing: isRegular ? 64 : 48) {
            SessionControlButton(
                title: model.isPaused ? "common.resume" : "common.pause",
                systemImage: model.isPaused ? "play.fill" : "pause.fill",
                role: .primary(tint),
                diameter: isRegular ? 96 : 84,
                action: model.togglePause
            )
            // Space bar pauses and resumes with a keyboard (iPad).
            .keyboardShortcut(.space, modifiers: [])
            SessionControlButton(
                title: "common.end",
                systemImage: "stop.fill",
                role: .destructive,
                diameter: isRegular ? 96 : 84,
                action: model.end
            )
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.isPaused)
    }

    private func color(for feedback: BiofeedbackAnalyzer.Feedback) -> Color {
        switch feedback {
        case .increasing: .green
        case .synchronized: tint
        case .collecting, .settling, .stable: .secondary
        }
    }

    private func average(of values: [Double]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((values.reduce(0, +) / Double(values.count)).rounded())
    }
}

#if DEBUG
#Preview {
    BreathingSessionView(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif

private struct BreathingCircle: View {
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

    /// Names the unit of the number above it: which cycle of the session this is,
    /// or how far through the set of breaths.
    @ViewBuilder
    private var caption: some View {
        switch position.readout {
        case .secondsLeft: Text("session.cycle \(position.cycle)")
        case .breathNumber: Text("session.breathOf \(totalBreaths)")
        }
    }

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
                caption
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

private struct LiveMetricCard: View {
    let value: String
    let label: LocalizedStringKey
    let values: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            TrendSparkline(values: values, tint: tint, capacity: BreathingSessionModel.liveChartCapacity)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.row))
    }
}

/// A large circular session control: a prominent, technique-tinted button for
/// the main action and a red glass button for ending the session.
private struct SessionControlButton: View {
    enum Role {
        case primary(Color)
        case destructive
    }

    let title: LocalizedStringKey
    let systemImage: String
    let role: Role
    let diameter: CGFloat
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            button
                .accessibilityLabel(title)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(labelColor)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var button: some View {
        let icon = Image(systemName: systemImage)
            .font(.system(size: diameter * 0.34, weight: .semibold))
            .contentTransition(.symbolEffect(.replace))
            .frame(width: diameter, height: diameter)

        switch role {
        case let .primary(tint):
            Button(action: action) { icon }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(tint)
        case .destructive:
            Button(action: action) { icon }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.red)
        }
    }

    private var labelColor: Color {
        switch role {
        case .primary: .primary
        case .destructive: .red
        }
    }
}
