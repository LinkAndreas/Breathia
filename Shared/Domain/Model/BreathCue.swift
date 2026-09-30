import Foundation

/// What to do during a breath phase beyond breathing in, holding, or breathing out
/// — hum, breathe through the nose, relax the jaw. A short phrase the session shows
/// under the circle while the phase lasts.
///
/// Cues are a shared vocabulary: a technique attaches them to its phases in
/// `TechniqueCatalog`, and the session shows whatever the current phase carries.
/// Their text is localized through the app's string catalog, under `cue.<name>`.
struct BreathCue: Hashable {
    /// What the cue is about, which picks its icon.
    enum Focus {
        case nose, mouth, sound, lungs, heart, ease
    }

    /// The string catalog key, which also tells cues apart.
    let id: String
    let text: String
    let focus: Focus

    init(_ key: String, focus: Focus) {
        id = key
        text = String(localized: String.LocalizationValue(key))
        self.focus = focus
    }
}

extension BreathCue {
    static let throughNose = BreathCue("cue.throughNose", focus: .nose)
    static let quietlyThroughNose = BreathCue("cue.quietlyThroughNose", focus: .nose)
    static let lightlyThroughNose = BreathCue("cue.lightlyThroughNose", focus: .nose)
    static let strongThroughNose = BreathCue("cue.strongThroughNose", focus: .nose)
    static let mouthClosedThroughNose = BreathCue("cue.mouthClosedThroughNose", focus: .nose)
    static let leftNostril = BreathCue("cue.leftNostril", focus: .nose)
    static let rightNostril = BreathCue("cue.rightNostril", focus: .nose)
    static let throughMouth = BreathCue("cue.throughMouth", focus: .mouth)
    static let slowlyThroughMouth = BreathCue("cue.slowlyThroughMouth", focus: .mouth)
    static let pursedLips = BreathCue("cue.pursedLips", focus: .mouth)
    static let curledTongue = BreathCue("cue.curledTongue", focus: .mouth)
    static let tongueBehindTeeth = BreathCue("cue.tongueBehindTeeth", focus: .mouth)
    static let hum = BreathCue("cue.hum", focus: .sound)
    static let oceanSound = BreathCue("cue.oceanSound", focus: .sound)
    static let tongueOut = BreathCue("cue.tongueOut", focus: .sound)
    static let fillBelly = BreathCue("cue.fillBelly", focus: .lungs)
    static let bellyRise = BreathCue("cue.bellyRise", focus: .lungs)
    static let bellyFall = BreathCue("cue.bellyFall", focus: .lungs)
    static let intoBelly = BreathCue("cue.intoBelly", focus: .lungs)
    static let intoRibs = BreathCue("cue.intoRibs", focus: .lungs)
    static let intoChest = BreathCue("cue.intoChest", focus: .lungs)
    static let secondSip = BreathCue("cue.secondSip", focus: .lungs)
    static let throughHeart = BreathCue("cue.throughHeart", focus: .heart)
    static let noPause = BreathCue("cue.noPause", focus: .ease)
    static let quietAndContinuous = BreathCue("cue.quietAndContinuous", focus: .ease)
    static let trailOff = BreathCue("cue.trailOff", focus: .ease)
    static let softer = BreathCue("cue.softer", focus: .ease)
    static let soften = BreathCue("cue.soften", focus: .ease)
    static let withoutStraining = BreathCue("cue.withoutStraining", focus: .ease)
    static let relaxJaw = BreathCue("cue.relaxJaw", focus: .ease)
    static let keepLight = BreathCue("cue.keepLight", focus: .ease)
    static let gentlePause = BreathCue("cue.gentlePause", focus: .ease)
}
