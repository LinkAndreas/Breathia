import SwiftUI

/// The place under the circle for the technique's cue — what to do during the
/// current phase beyond breathing. Second to the circle: small, quiet, and changing
/// only when the instruction does, so a cue that spans phases simply stays.
struct BreathCueSlot: View {
    let technique: Technique
    /// The cue to show now, if the current phase has one.
    let cue: BreathCue?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Every cue of the technique, unseen, so the slot is always as tall as
            // its tallest and the circle above never moves as they come and go.
            ForEach(technique.cues, id: \.self) { cue in
                BreathCueLabel(cue: cue, tint: technique.tint)
                    .hidden()
            }
            if let cue {
                BreathCueLabel(cue: cue, tint: technique.tint)
                    .id(cue)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.blurReplace))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: cue)
        // Second to the circle at every text size: past this, the cue would take
        // the circle's room and outgrow the phase it belongs to.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

#if DEBUG
#Preview {
    BreathCueSlot(technique: TechniqueCatalog.technique(withID: "humming"), cue: .hum)
}
#endif
