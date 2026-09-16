import SwiftUI

extension Technique {
    /// Accent for orbs, charts, chips, and buttons.
    var tint: Color { Color(oklch: 0.62, chroma: 0.15, hue: hue) }
    /// Slightly deeper fill for the large technique tiles, so white text stays legible.
    var tileColor: Color { Color(oklch: 0.58, chroma: 0.14, hue: hue) }
    var glowColor: Color { Color(oklch: 0.5, chroma: 0.15, hue: hue) }
}
