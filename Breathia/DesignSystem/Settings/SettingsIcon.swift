import SwiftUI

/// A white symbol on a coloured, rounded tile — the icon style of the Settings app.
struct SettingsIcon: View {
    let systemImage: String
    let color: Color

    #if os(macOS)
    private static let side: CGFloat = 22
    #else
    private static let side: CGFloat = 29
    #endif

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: Self.side * 0.52, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: Self.side, height: Self.side)
            .background(color.gradient, in: .rect(cornerRadius: Self.side * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}
