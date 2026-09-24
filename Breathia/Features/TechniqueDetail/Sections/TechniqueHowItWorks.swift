import SwiftUI

/// How the technique works, as a paragraph.
struct TechniqueHowItWorks: View {
    let technique: Technique

    var body: some View {
        Text(technique.howItWorks)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    TechniqueHowItWorks(technique: TechniqueCatalog.all[1])
        .padding()
}
#endif
