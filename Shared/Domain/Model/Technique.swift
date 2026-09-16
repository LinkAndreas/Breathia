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

    /// "4s Inhale"
    var label: String { String(localized: "technique.phaseLabel \(seconds) \(kind.title)", comment: "Breath phase, e.g. '4s Inhale'") }

    static func inhale(_ seconds: Int, scale: Double = 1.15) -> BreathPhase {
        BreathPhase(kind: .inhale, seconds: seconds, scale: scale)
    }

    static func hold(_ seconds: Int, scale: Double) -> BreathPhase {
        BreathPhase(kind: .hold, seconds: seconds, scale: scale)
    }

    static func exhale(_ seconds: Int, scale: Double = 0.8) -> BreathPhase {
        BreathPhase(kind: .exhale, seconds: seconds, scale: scale)
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

    var cycleDuration: Int { phases.reduce(0) { $0 + $1.seconds } }
    var patternLabel: String { phases.map(\.label).joined(separator: " · ") }
    var shortPattern: String { phases.map { String($0.seconds) }.joined(separator: "-") }
    var durationLabel: String { String(localized: "technique.durationMinutes \(recommendedDuration / 60)", comment: "Session length in minutes") }
}
