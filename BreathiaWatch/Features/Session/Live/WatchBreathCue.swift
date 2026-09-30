import SwiftUI

/// The technique's cue for the current phase on Apple Watch: its icon and a short
/// phrase under the circle. While the session is paused, it says so instead.
struct WatchBreathCue: View {
    let cue: BreathCue?
    let tint: Color
    var isPaused = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transition: AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }

    var body: some View {
        ZStack {
            if isPaused {
                Text("watch.session.paused")
                    .font(.footnote.weight(.semibold))
                    .transition(transition)
            } else if let cue {
                // The icon leads the first line, so the phrase wraps as one text.
                Text("\(Text(Image(systemName: cue.focus.systemImage)).foregroundStyle(tint)) \(cue.text)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .accessibilityLabel(cue.text)
                    .id(cue)
                    .transition(transition)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: cue)
        .animation(.easeInOut(duration: 0.3), value: isPaused)
        // Past this the phrase no longer fits under the circle.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

#if DEBUG
#Preview {
    WatchBreathCue(cue: .hum, tint: TechniqueCatalog.all[1].tint)
}
#endif
