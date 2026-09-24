import SwiftUI

#if !os(macOS)
/// A technique's details on iPhone and iPad, with the start button floating at the bottom.
struct TechniqueDetailPage: View {
    let technique: Technique
    let onStart: (Technique) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TechniqueDetailHeader(technique: technique)

                RhythmCard(technique: technique)
                    .padding(.top, 18)

                SectionHeader(title: "technique.detail.howItWorks")
                TechniqueHowItWorks(technique: technique)
                    .padding(.horizontal, 4)

                SectionHeader(title: "technique.detail.bestFor")
                TechniqueBestForList(technique: technique)
                    .padding(.horizontal, 4)

                SectionHeader(title: "technique.detail.howToPractice")
                TechniqueSteps(technique: technique)
                    .padding(.horizontal, 4)

                Callout(text: technique.safetyNote, isSecondary: true)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .readableContentWidth()
        }
        .background(Theme.Palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            // Floats over the explanations so a session is one tap away at any scroll position.
            PrimaryActionButton(title: "technique.detail.startThisTechnique", tint: technique.tint) {
                onStart(technique)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .readableContentWidth(560)
        }
    }
}
#endif
