import SwiftUI

#if os(macOS)
/// The technique's orb, name, and purpose, with the start button beside them.
struct MacTechniqueDetailHeader: View {
    let technique: Technique
    let onStart: (Technique) -> Void

    var body: some View {
        HStack(spacing: 18) {
            TechniqueOrb(technique: technique, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(technique.name)
                    .font(.largeTitle.bold())
                Text(technique.purpose)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            Button {
                onStart(technique)
            } label: {
                Label("technique.detail.startThisTechnique", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(technique.tint)
            // Return starts the session.
            .keyboardShortcut(.defaultAction)
        }
    }
}
#endif

#if DEBUG && os(macOS)
#Preview {
    MacTechniqueDetailHeader(technique: TechniqueCatalog.all[1], onStart: { _ in })
        .padding()
}
#endif
