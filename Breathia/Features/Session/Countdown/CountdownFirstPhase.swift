import SwiftUI

/// Which phase the technique starts with, so the first breath isn't a surprise.
struct CountdownFirstPhase: View {
    let technique: Technique

    var body: some View {
        if let firstPhase = technique.phases.first {
            Label {
                Text("session.countdown.firstPhase \(firstPhase.label)")
            } icon: {
                Image(systemName: "wind")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.Palette.elevated, in: .capsule)
        }
    }
}

#if DEBUG
#Preview {
    CountdownFirstPhase(technique: TechniqueCatalog.all[1])
        .padding()
}
#endif
