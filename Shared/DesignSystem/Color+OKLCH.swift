import SwiftUI

extension Color {
    /// Creates a colour from OKLCH components — the space the design specifies
    /// technique colours in, because equal hue steps there look equally vivid.
    init(oklch lightness: Double, chroma: Double, hue: Double, opacity: Double = 1) {
        let radians = hue * .pi / 180
        let a = chroma * cos(radians)
        let b = chroma * sin(radians)

        let l = pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3)
        let m = pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3)
        let s = pow(lightness - 0.0894841775 * a - 1.2914855480 * b, 3)

        func clamp(_ value: Double) -> Double { min(1, max(0, value)) }

        self.init(
            .sRGBLinear,
            red: clamp(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
            green: clamp(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
            blue: clamp(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
            opacity: opacity
        )
    }
}
