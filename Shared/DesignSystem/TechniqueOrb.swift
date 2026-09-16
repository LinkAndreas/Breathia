import SwiftUI

/// The glowing colour dot that represents a technique throughout the app.
struct TechniqueOrb: View {
    let technique: Technique
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(technique.tint)
            .frame(width: size, height: size)
            .shadow(color: technique.glowColor.opacity(0.8), radius: size / 7)
            .accessibilityHidden(true)
    }
}
