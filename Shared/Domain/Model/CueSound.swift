import Foundation

/// The sound that marks each turn of the breath. Every sound plays a higher note
/// for breathing in, a lower one for breathing out and a quiet middle one for a
/// hold, so the phases can be told apart with closed eyes.
enum CueSound: String, Codable, CaseIterable, Identifiable {
    /// A struck singing bowl: warm, with a long, shimmering ring.
    case bowl
    /// A small bell: brighter and clearer, carries over background noise.
    case bell
    /// A soft wooden mallet: short and distinct, leaves silence in between.
    case wood
    /// A tone that lasts the whole phase, rising while breathing in and falling
    /// while breathing out, so the pace can be followed without counting.
    case wave

    var id: Self { self }

    var title: String {
        switch self {
        case .bowl: String(localized: "settings.cueSound.bowl", comment: "Breathing cue sound: a singing bowl")
        case .bell: String(localized: "settings.cueSound.bell", comment: "Breathing cue sound: a small bell")
        case .wood: String(localized: "settings.cueSound.wood", comment: "Breathing cue sound: a soft wooden mallet")
        case .wave: String(localized: "settings.cueSound.wave", comment: "Breathing cue sound: a tone that rises and falls with the breath")
        }
    }
}
