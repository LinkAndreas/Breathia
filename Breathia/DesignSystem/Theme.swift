import SwiftUI

/// Design tokens for the Breathing Coach UI. Colours are semantic system colours,
/// so light and dark appearance come for free; each technique layers its own hue
/// on top (see `Technique+Style`).
enum Theme {
    enum Radius {
        static let card: CGFloat = 20
        static let row: CGFloat = 18
        static let tile: CGFloat = 22
        static let callout: CGFloat = 16
    }

    enum Palette {
        #if os(macOS)
        /// Matches the Mac's grouped forms, so every column and page shares one surface:
        /// white in light mode, the window colour in dark mode.
        static let background = adaptive(light: .textBackgroundColor, dark: .windowBackgroundColor)
        /// Cards as in grouped forms: a light tint over the page in either appearance.
        static let elevated = adaptive(
            light: NSColor.black.withAlphaComponent(0.035),
            dark: NSColor.white.withAlphaComponent(0.07)
        )
        static let tertiaryLabel = Color(nsColor: .tertiaryLabelColor)
        #else
        static let background = Color(.systemGroupedBackground)
        static let elevated = Color(.secondarySystemGroupedBackground)
        static let tertiaryLabel = Color(.tertiaryLabel)
        #endif
        static let subtleFill = Color.primary.opacity(0.05)
        static let calloutFill = Color.primary.opacity(0.04)
        static let connected = Color.green
        static let disconnected = tertiaryLabel

        #if os(macOS)
        private static func adaptive(light: NSColor, dark: NSColor) -> Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            })
        }
        #endif
    }
}
