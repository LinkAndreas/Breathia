import SwiftUI

#if os(macOS)
/// A document-style page: the start action sits in the header next to the name,
/// where a Mac window's main action belongs, and the explanations use two
/// columns when the window is wide enough.
struct MacTechniqueDetailPage: View {
    let technique: Technique
    let onStart: (Technique) -> Void

    /// Width available to the page, for choosing one or two text columns.
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                MacTechniqueDetailHeader(technique: technique, onStart: onStart)
                RhythmCard(technique: technique)

                if contentWidth >= 720 {
                    HStack(alignment: .top, spacing: 40) {
                        VStack(alignment: .leading, spacing: 28) {
                            MacTechniqueSection("technique.detail.howItWorks") { TechniqueHowItWorks(technique: technique) }
                            MacTechniqueSection("technique.detail.bestFor") { TechniqueBestForList(technique: technique) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        MacTechniqueSection("technique.detail.howToPractice") { TechniqueSteps(technique: technique) }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    MacTechniqueSection("technique.detail.howItWorks") { TechniqueHowItWorks(technique: technique) }
                    MacTechniqueSection("technique.detail.bestFor") { TechniqueBestForList(technique: technique) }
                    MacTechniqueSection("technique.detail.howToPractice") { TechniqueSteps(technique: technique) }
                }

                Callout(text: technique.safetyNote, isSecondary: true)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .onGeometryChange(for: CGFloat.self) { $0.size.width - 64 } action: { contentWidth = $0 }
            .readableContentWidth(980)
        }
        .background(Theme.Palette.background)
    }
}
#endif
