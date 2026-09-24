import SwiftUI

struct TechniqueDetailView: View {
    let technique: Technique
    let onStart: (Technique) -> Void

    var body: some View {
        #if os(macOS)
        MacTechniqueDetailPage(technique: technique, onStart: onStart)
        #else
        TechniqueDetailPage(technique: technique, onStart: onStart)
        #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TechniqueDetailView(technique: TechniqueCatalog.all[0], onStart: { _ in })
    }
}
#endif
