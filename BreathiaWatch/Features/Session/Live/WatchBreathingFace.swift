import SwiftUI

/// The breathing page at one moment, read from the top: heart rate and time
/// remaining beside the clock, the phase's name, the circle with its count, and the
/// technique's cue. Dimmed for Always On, it keeps the count and drops what moves.
struct WatchBreathingFace: View {
    let model: BreathingSessionModel
    let date: Date
    /// The page's size, the room beside the clock included.
    let size: CGSize
    /// The height of the status row beside the clock.
    let statusRoom: CGFloat
    var isDimmed = false

    /// The height of the phase's name above the circle.
    @ScaledMetric(relativeTo: .body) private var titleRoom: CGFloat = 22
    /// The height of one line of the cue under the circle.
    @ScaledMetric(relativeTo: .caption2) private var cueLineHeight: CGFloat = 15

    /// The room under the circle for the cue's two lines, or "Paused".
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
        let height = size.height - statusRoom - titleRoom - cueRoom
        let side = min(size.width, height)
        VStack(spacing: 0) {
            WatchSessionStatus(model: model)
                .padding(.leading, 10)
                .frame(height: statusRoom, alignment: .bottom)
            Group {
                WatchPhaseTitle(phase: position.phase)
                    .frame(height: titleRoom)
                    // The circle speaks for both.
                    .accessibilityHidden(true)
                WatchBreathingCircle(
                    position: position,
                    tint: model.technique.tint,
                    // At its largest the circle just fills the room left to it.
                    diameter: side * 0.94 / scaleRange.largest,
                    smallestScale: scaleRange.smallest,
                    totalBreaths: totalBreaths,
                    isDimmed: isDimmed
                )
                .frame(width: size.width, height: height)
            }
            .opacity(model.isPaused ? 0.45 : 1)
            // Always On leaves the cue out: the taps carry the breath with the wrist down.
            WatchBreathCue(cue: isDimmed ? nil : position.cue, tint: model.technique.tint, isPaused: model.isPaused)
                .padding(.horizontal, 8)
                .frame(height: cueRoom)
        }
    }
}

#if DEBUG
#Preview("Dimmed") {
    WatchBreathingFace(
        model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]),
        date: .now,
        size: CGSize(width: 198, height: 220),
        statusRoom: 24,
        isDimmed: true
    )
}
#endif
