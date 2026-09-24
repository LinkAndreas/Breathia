import SwiftUI

#if os(macOS)
/// A titled section of the Mac's technique page.
struct MacTechniqueSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}
#endif

#if DEBUG && os(macOS)
#Preview {
    MacTechniqueSection("technique.detail.howItWorks") {
        TechniqueHowItWorks(technique: TechniqueCatalog.all[1])
    }
    .padding()
}
#endif
