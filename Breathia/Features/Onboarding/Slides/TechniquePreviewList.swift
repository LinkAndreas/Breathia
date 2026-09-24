import SwiftUI

/// A miniature of the Breathe list: a few real techniques, each in its own colour,
/// fading out toward the bottom to hint at the rest of the catalog.
struct TechniquePreviewList: View {
    private static let techniqueIDs: [Technique.ID] = ["resonance", "box", "478", "sigh"]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(Self.techniqueIDs.enumerated()), id: \.element) { index, id in
                let technique = TechniqueCatalog.technique(withID: id)
                HStack(spacing: 10) {
                    TechniqueOrb(technique: technique, size: 24)
                    Text(technique.name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(verbatim: technique.shortPattern)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(technique.tint)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.Palette.elevated, in: .rect(cornerRadius: 12))
                .opacity(1 - Double(index) * 0.2)
            }
        }
        .frame(width: 260)
    }
}
