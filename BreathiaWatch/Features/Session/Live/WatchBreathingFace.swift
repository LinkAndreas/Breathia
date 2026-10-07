import SwiftUI

/// The breathing page at one moment, read from the top: heart rate and time
/// remaining beside the clock, the phase's name, the count filling the middle, a
/// bar that follows the breath, and the technique's cue. Always On shows the same
/// face, quieter and redrawn once a second, so lowering the wrist changes nothing
/// but the light.
struct WatchBreathingFace: View {
    let model: BreathingSessionModel
    let date: Date
    /// The page's size, the room beside the clock included.
    let size: CGSize
    /// The height of the status row beside the clock.
    let statusRoom: CGFloat
    var isDimmed = false

    /// The height of the phase's name above the count.
    @ScaledMetric(relativeTo: .headline) private var titleRoom: CGFloat = 24
    /// The height of one line of the cue under the count.
    @ScaledMetric(relativeTo: .footnote) private var cueLineHeight: CGFloat = 18

    /// The room under the count for the bar.
    private let meterRoom: CGFloat = 14
    /// The room at the bottom for the cue's two lines, or "Paused".
    private var cueRoom: CGFloat { cueLineHeight * 2 }

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
        let position = model.position(at: date)
        let counterHeight = max(0, size.height - statusRoom - titleRoom - meterRoom - cueRoom)
        VStack(spacing: 0) {
            WatchSessionStatus(model: model, remaining: model.remaining(at: date))
                .padding(.leading, 10)
                .frame(height: statusRoom, alignment: .bottom)
            Group {
                WatchPhaseTitle(phase: position.phase, tint: model.technique.tint, isDimmed: isDimmed)
                    .frame(height: titleRoom)
                    // The count speaks for both.
                    .accessibilityHidden(true)
                WatchBreathCounter(
                    position: position,
                    totalBreaths: totalBreaths,
                    height: counterHeight,
                    isDimmed: isDimmed
                )
                .frame(height: counterHeight)
                WatchBreathMeter(
                    position: position,
                    tint: model.technique.tint,
                    scaleRange: scaleRange,
                    isDimmed: isDimmed
                )
                .frame(width: size.width * 0.6, height: 6)
                .frame(height: meterRoom)
            }
            .opacity(model.isPaused ? 0.45 : 1)
            WatchBreathCue(cue: position.cue, tint: model.technique.tint, isPaused: model.isPaused, isDimmed: isDimmed)
                .padding(.horizontal, 12)
                .frame(height: cueRoom)
        }
    }
}

#if DEBUG
#Preview("Active") {
    WatchBreathingFace(
        model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]),
        date: .now,
        size: CGSize(width: 198, height: 242),
        statusRoom: 24
    )
}

#Preview("Dimmed") {
    WatchBreathingFace(
        model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]),
        date: .now,
        size: CGSize(width: 198, height: 242),
        statusRoom: 24,
        isDimmed: true
    )
}
#endif
