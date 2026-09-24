import SwiftUI

/// A past session's technique and when or how long it ran, at the top of its page.
struct HistorySessionHeader: View {
    let technique: Technique
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            TechniqueOrb(technique: technique, size: 44)
            Text(technique.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        // On a Mac the page scrolls right under the toolbar, which would cut off the
        // orb's glow; give it room.
        #if os(macOS)
        .padding(.top, 24)
        #else
        .padding(.top, 6)
        #endif
    }
}

#if DEBUG
#Preview {
    HistorySessionHeader(technique: PreviewData.sessions[0].technique, subtitle: Formatters.clock(PreviewData.sessions[0].duration))
}
#endif
