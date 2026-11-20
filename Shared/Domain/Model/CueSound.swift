import Foundation

/// The sound that marks each turn of the breath. Every sound plays a higher note
/// for breathing in, a lower one for breathing out and a quiet middle one for a
/// hold, so the phases can be told apart with closed eyes.
enum CueSound: String, Codable, CaseIterable, Identifiable {
    /// A singing bowl struck with a felt mallet: warm, with a long, gently
    /// pulsing ring.
    case bowl
    /// A crystal singing bowl: a pure tone that blooms softly and lingers.
    case crystal
    /// A small handbell struck softly: a pure, round tone, a little clearer.
    case bell
    /// Three tubes of a wind chime touched one after another, softly.
    case chimes
    /// A kalimba's metal tine plucked by a thumb: a short, warm, wooden ring.
    case kalimba
    /// A marimba bar under a yarn mallet: short and woody, leaves quiet in between.
    case wood
    /// A soft, breath-like sound that lasts the whole phase, swelling while
    /// breathing in and receding while breathing out, so the pace can be followed
    /// without counting.
    case wave
    /// The sea on a quiet shore for the whole phase: a wave rolls in while
    /// breathing in and washes back while breathing out.
    case ocean

    var id: Self { self }

    /// Whether the sound lasts the whole phase rather than marking its start.
    var lastsWholePhase: Bool {
        switch self {
        case .wave, .ocean: true
        case .bowl, .crystal, .bell, .chimes, .kalimba, .wood: false
        }
    }

    /// Sounds that mark the turn of the breath, in the order they're offered.
    static let struck: [CueSound] = [.bowl, .crystal, .bell, .chimes, .kalimba, .wood]
    /// Sounds that follow the breath all the way.
    static let flowing: [CueSound] = [.wave, .ocean]

    var title: String {
        switch self {
        case .bowl: String(localized: "settings.cueSound.bowl", comment: "Breathing cue sound: a singing bowl")
        case .crystal: String(localized: "settings.cueSound.crystal", comment: "Breathing cue sound: a crystal singing bowl")
        case .bell: String(localized: "settings.cueSound.bell", comment: "Breathing cue sound: a small bell")
        case .chimes: String(localized: "settings.cueSound.chimes", comment: "Breathing cue sound: a wind chime")
        case .kalimba: String(localized: "settings.cueSound.kalimba", comment: "Breathing cue sound: a kalimba (thumb piano)")
        case .wood: String(localized: "settings.cueSound.wood", comment: "Breathing cue sound: a soft wooden mallet")
        case .wave: String(localized: "settings.cueSound.wave", comment: "Breathing cue sound: a tone that rises and falls with the breath")
        case .ocean: String(localized: "settings.cueSound.ocean", comment: "Breathing cue sound: ocean waves")
        }
    }
}
