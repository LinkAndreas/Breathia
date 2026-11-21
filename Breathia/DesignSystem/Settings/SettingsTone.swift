import SwiftUI

/// The colour of a settings icon, from the same family as the techniques' orbs:
/// one lightness and chroma in OKLCH, only the hue changes, so every icon is
/// equally vivid and none shouts.
///
/// Each settings section has its own hue family, as each technique category does:
/// the heart in rose, the breath in teal, sound in violet, the body's response in
/// green, the app itself in calm blues. Rows within a section step a little
/// around their family's hue, so they belong together and still tell apart.
struct SettingsTone: Equatable {
    let hue: Double
    var chroma = 0.15
    /// Extra lightness. Yellow and amber at the family's lightness turn brown
    /// and olive; lifted, they glow like the sun in the app icon.
    var lift = 0.0

    /// The tile's light: brighter and a touch warmer at the top, as if lit from
    /// above, like the glow in the app icon.
    var top: Color { Color(oklch: 0.71 + lift, chroma: chroma * 0.85, hue: hue - 8) }
    var bottom: Color { Color(oklch: 0.58 + lift, chroma: chroma, hue: hue + 4) }

    // Heart: the sensor and Apple Health.
    static let heart = SettingsTone(hue: 352)
    static let health = SettingsTone(hue: 340)

    // Breath: teal, like the calm techniques.
    static let breathing = SettingsTone(hue: 190)
    static let haptics = SettingsTone(hue: 178)
    static let countdown = SettingsTone(hue: 204)

    // Sound: violet, like the evening techniques.
    static let sound = SettingsTone(hue: 285)
    static let soundCues = SettingsTone(hue: 273)
    static let cueSound = SettingsTone(hue: 288)
    static let cueVolume = SettingsTone(hue: 300)
    static let cuePreview = SettingsTone(hue: 270)

    // The body's response: green, like the stress-relief techniques.
    static let biofeedback = SettingsTone(hue: 150)
    static let hrvMetric = SettingsTone(hue: 144)
    static let sensitivity = SettingsTone(hue: 162)

    // How the app looks, and its History: warm light.
    static let appearance = SettingsTone(hue: 236)
    static let history = SettingsTone(hue: 52, lift: 0.04)
    /// Deleting: the coral of the heart family, a little stronger, so it reads as a warning.
    static let destructive = SettingsTone(hue: 24, chroma: 0.17)

    // Feedback: honey, like the energising techniques — warm and thankful.
    static let rate = SettingsTone(hue: 78, chroma: 0.14, lift: 0.1)
    static let feedback = SettingsTone(hue: 62, chroma: 0.14, lift: 0.08)
    static let share = SettingsTone(hue: 46, chroma: 0.14, lift: 0.06)

    // About the app: quiet blues, and grey for plain information.
    static let privacy = SettingsTone(hue: 240)
    static let information = SettingsTone(hue: 240, chroma: 0.03)
    static let whatsNew = SettingsTone(hue: 226)
    static let versionHistory = SettingsTone(hue: 212)
    static let onboarding = SettingsTone(hue: 258)
}
