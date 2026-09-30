import SwiftUI

/// The breathing page, read from the top: heart rate and time remaining beside the
/// clock, the phase's name, the circle with its count, and the technique's cue.
struct WatchBreathingPage: View {
    let model: BreathingSessionModel

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

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
        GeometryReader { proxy in
            // The page reaches up beside the clock: the status takes the clock's row,
            // and everything else moves up with it.
            let statusRoom = proxy.safeAreaInsets.top * 0.56
            let pageHeight = proxy.size.height + proxy.safeAreaInsets.top
            let height = pageHeight - statusRoom - titleRoom - cueRoom
            let side = min(proxy.size.width, height)
            // Always On: hold the circle still instead of animating at a low frame rate.
            TimelineView(.animation(paused: model.isPaused || isLuminanceReduced)) { context in
                let position = model.position(at: context.date)
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
                            totalBreaths: totalBreaths
                        )
                        .frame(width: proxy.size.width, height: height)
                    }
                    .opacity(model.isPaused ? 0.45 : 1)
                    WatchBreathCue(cue: position.cue, tint: model.technique.tint, isPaused: model.isPaused)
                        .padding(.horizontal, 8)
                        .frame(height: cueRoom)
                }
            }
            .frame(width: proxy.size.width, height: pageHeight)
            .offset(y: -proxy.safeAreaInsets.top)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchBreathingPage(model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
    }
}
#endif
