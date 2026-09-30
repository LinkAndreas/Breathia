import SwiftUI

/// The session's breathing circle, sized to its pane and following the clock, with
/// the technique's cue for the current phase under it.
struct LiveBreathingCircle: View {
    let model: BreathingSessionModel

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
        TimelineView(.animation(paused: model.isPaused)) { context in
            let position = model.position(at: context.date)
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    BreathingCircle(
                        position: position,
                        tint: model.technique.tint,
                        // Even at its fullest the circle keeps clear of the pane's
                        // edges and of the cue under it.
                        diameter: min(Self.maximumCircleDiameter, min(proxy.size.width, proxy.size.height) / 1.32),
                        smallestScale: smallestScale,
                        totalBreaths: totalBreaths
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
                BreathCueSlot(technique: model.technique, cue: position.cue)
            }
        }
    }
}

#if DEBUG
#Preview {
    LiveBreathingCircle(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
