import SwiftUI

#if !os(macOS)
/// The technique's orb, name, and purpose, centred at the top of its page.
struct TechniqueDetailHeader: View {
    let technique: Technique

    var body: some View {
        VStack(spacing: 6) {
            TechniqueOrb(technique: technique, size: 60)
                .padding(.bottom, 4)
            Text(technique.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(technique.purpose)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }
}
#endif
