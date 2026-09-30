import Foundation

struct BreathPhase: Hashable {
    enum Kind: String {
        case inhale, hold, exhale

        var title: String {
            switch self {
            case .inhale: String(localized: "technique.inhale")
            case .hold: String(localized: "technique.hold")
            case .exhale: String(localized: "technique.exhale")
            }
        }
    }

    let kind: Kind
    let seconds: Int
    /// Relative size of the breathing circle at the end of this phase.
    let scale: Double
    /// What to do during this phase beyond breathing in, holding, or breathing out.
    /// Empty when there's nothing to add. More than one take turns, cycle by cycle —
    /// how a technique alternates nostrils.
    var cues: [BreathCue] = []

    /// "4s Inhale"
    var label: String { String(localized: "technique.phaseLabel \(seconds) \(kind.title)", comment: "Breath phase, e.g. '4s Inhale'") }

    /// The cue to show during this phase of the given 1-based cycle, if any.
    func cue(inCycle cycle: Int) -> BreathCue? {
        guard !cues.isEmpty else { return nil }
        return cues[max(0, cycle - 1) % cues.count]
    }

    static func inhale(_ seconds: Int, scale: Double = 1.15, cue: BreathCue...) -> BreathPhase {
        BreathPhase(kind: .inhale, seconds: seconds, scale: scale, cues: cue)
    }

    static func hold(_ seconds: Int, scale: Double, cue: BreathCue...) -> BreathPhase {
        BreathPhase(kind: .hold, seconds: seconds, scale: scale, cues: cue)
    }

    static func exhale(_ seconds: Int, scale: Double = 0.8, cue: BreathCue...) -> BreathPhase {
        BreathPhase(kind: .exhale, seconds: seconds, scale: scale, cues: cue)
    }
}

/// A breathing technique. Its text fields are already localized — see
/// `TechniqueCatalog`, which reads them from the app's string catalog.
struct Technique: Identifiable, Hashable {
    typealias ID = String

    let id: ID
    let name: String
    let summary: String
    let purpose: String
    let category: TechniqueCategory
    let isBeginnerFriendly: Bool
    /// Target session length in seconds.
    let recommendedDuration: Int
    let phases: [BreathPhase]
    let howItWorks: String
    let bestFor: [String]
    let steps: [String]
    let safetyNote: String
    /// Hue (in degrees) of the technique's signature colour.
    let hue: Double

    /// Every cue the technique shows during a session, each once, in order of appearance.
    var cues: [BreathCue] {
        phases.flatMap(\.cues).reduce(into: []) { cues, cue in
            if !cues.contains(cue) { cues.append(cue) }
        }
    }

    var cycleDuration: Int { phases.reduce(0) { $0 + $1.seconds } }
    var patternLabel: String { phases.map(\.label).joined(separator: " · ") }
    var shortPattern: String { phases.map { String($0.seconds) }.joined(separator: "-") }
    var durationLabel: String { String(localized: "technique.durationMinutes \(recommendedDuration / 60)", comment: "Session length in minutes") }
}
