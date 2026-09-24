import SwiftUI

/// The glowing colour dot that represents a technique throughout the app.
struct TechniqueOrb: View {
    let technique: Technique
    var size: CGFloat = 48

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        Circle()
            .fill(technique.tint)
            .frame(width: size, height: size)
            // Always On: drop the glow, which only smears on the dimmed screen.
            // A shadow costs no layout, so the orb keeps its size either way.
            .shadow(
                color: technique.glowColor.opacity(isLuminanceReduced ? 0 : 0.8),
                radius: isLuminanceReduced ? 0 : size / 7
            )
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        TechniqueOrb(technique: TechniqueCatalog.all[0], size: 24)
        TechniqueOrb(technique: TechniqueCatalog.all[1])
        TechniqueOrb(technique: TechniqueCatalog.all[2], size: 64)
    }
    .padding()
}
#endif
