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
