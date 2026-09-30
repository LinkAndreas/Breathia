import SwiftUI

/// One cue: its icon in the technique's colour and a short phrase, in a quiet pill.
struct BreathCueLabel: View {
    let cue: BreathCue
    let tint: Color

    var body: some View {
        Label {
            Text(cue.text)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        } icon: {
            Image(systemName: cue.focus.systemImage)
                .foregroundStyle(tint)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.Palette.elevated, in: .capsule)
    }
}

#if DEBUG
#Preview {
    BreathCueLabel(cue: .hum, tint: TechniqueCatalog.all[1].tint)
        .padding()
}
#endif
