import SwiftUI

/// The session's breathing circle, sized to its pane and following the clock.
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
        GeometryReader { proxy in
            TimelineView(.animation(paused: model.isPaused)) { context in
                BreathingCircle(
                    position: model.position(at: context.date),
                    tint: model.technique.tint,
                    diameter: min(Self.maximumCircleDiameter, min(proxy.size.width, proxy.size.height) / 1.2),
                    smallestScale: smallestScale,
                    totalBreaths: totalBreaths
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}

#if DEBUG
#Preview {
    LiveBreathingCircle(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
