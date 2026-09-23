import Foundation

/// Maps elapsed session time onto a technique's repeating phase pattern.
/// Pure and deterministic, so the breathing circle can sample it every frame.
struct BreathingClock {
    struct Position: Equatable {
        /// What the circle's big number says.
        enum Readout: Equatable {
            /// Seconds left in the current breath, counting down N…1 — the pacing
            /// a breath long enough to count needs.
            case secondsLeft(Int)
            /// Which breath this is, counting up from 1. Fast patterns are practised
            /// in breaths rather than seconds, and a one-second phase would leave a
            /// countdown showing the same number from start to finish.
            case breathNumber(Int)

            var value: Int {
                switch self {
                case let .secondsLeft(value), let .breathNumber(value): value
                }
            }

            var countsDown: Bool {
                if case .secondsLeft = self { true } else { false }
            }
        }

        let phaseIndex: Int
        let phase: BreathPhase
        /// 1-based cycle number — one cycle is one whole breath.
        let cycle: Int
        /// Whole seconds left in the current phase, counting down to 1.
        let secondsRemaining: Int
        /// The number shown in the circle. See `Readout`.
        let readout: Readout
        /// How far through the current phase, from 0 at its start to 1 at its end.
        let phaseProgress: Double
        /// Circle scale, eased from the previous phase's scale to this one's.
        let scale: Double

        /// Time left until the phase turns over — how long the session loop may
        /// sleep before it owes the user a cue.
        var timeUntilPhaseEnd: TimeInterval { Double(phase.seconds) * (1 - phaseProgress) }
    }

    /// A breath shorter than this can't be counted down — `4…1` would collapse to a
    /// single number held for the whole breath — so the circle counts breaths instead.
    private static let countableBreathSeconds = 2

    let phases: [BreathPhase]
    /// Length of the shortest breath in the pattern, where consecutive phases of one
    /// kind count as one breath, as they do for the readout.
    private let shortestBreath: Int

    /// Whether the pattern runs faster than seconds can usefully describe. Decided
    /// once per technique, never per phase, so the big number keeps one meaning for
    /// the whole session.
    private var isFast: Bool { shortestBreath < Self.countableBreathSeconds }

    init(technique: Technique) {
        let phases = technique.phases
        self.phases = phases
        shortestBreath = phases.indices
            .map { index in Self.breath(around: index, in: phases).reduce(0) { $0 + phases[$1].seconds } }
            .min() ?? 0
    }

    func position(at elapsed: TimeInterval) -> Position {
        let cycleLength = Double(phases.reduce(0) { $0 + $1.seconds })
        guard cycleLength > 0 else {
            return Position(phaseIndex: 0, phase: phases[0], cycle: 1, secondsRemaining: 0, readout: .secondsLeft(0), phaseProgress: 0, scale: 1)
        }

        let elapsed = max(0, elapsed)
        let cycle = Int(elapsed / cycleLength)
        var offset = elapsed - Double(cycle) * cycleLength

        for (index, phase) in phases.enumerated() {
            let length = Double(phase.seconds)
            if offset < length || index == phases.count - 1 {
                let progress = min(1, offset / length)
                let previous = phases[(index - 1 + phases.count) % phases.count]
                return Position(
                    phaseIndex: index,
                    phase: phase,
                    cycle: cycle + 1,
                    secondsRemaining: Self.secondsLeft(of: length, after: offset),
                    readout: isFast
                        ? .breathNumber(cycle + 1)
                        : .secondsLeft(secondsLeftOfBreath(at: index, offset: min(offset, length))),
                    phaseProgress: progress,
                    scale: previous.scale + (phase.scale - previous.scale) * ease(progress)
                )
            }
            offset -= length
        }
        preconditionFailure("unreachable: the last phase always matches")
    }

    /// Seconds left in the whole breath, `offset` seconds into phase `index`.
    private func secondsLeftOfBreath(at index: Int, offset: TimeInterval) -> Int {
        let breath = Self.breath(around: index, in: phases)
        let breathLength = breath.reduce(0) { $0 + phases[$1].seconds }
        let intoBreath = Double(phases[breath.lowerBound..<index].reduce(0) { $0 + $1.seconds }) + offset
        // N during the first second, 1 during the last.
        return Self.secondsLeft(of: Double(breathLength), after: intoBreath)
    }

    /// The breath phase `index` belongs to: itself plus the run of same-kind phases
    /// around it, so a top-up inhale carries on from the one before.
    private static func breath(around index: Int, in phases: [BreathPhase]) -> ClosedRange<Int> {
        let kind = phases[index].kind
        var first = index
        while first > 0, phases[first - 1].kind == kind { first -= 1 }
        var last = index
        while last < phases.count - 1, phases[last + 1].kind == kind { last += 1 }
        return first...last
    }

    /// Whole seconds left, counting down to 1 (never 0 while the span lasts).
    private static func secondsLeft(of length: TimeInterval, after offset: TimeInterval) -> Int {
        max(1, Int((length - offset).rounded(.up)))
    }

    /// Slow breaths start and finish gently rather than at constant speed. Fast ones
    /// take off at once and settle, so the turn of each phase stays legible at a
    /// pace where the number can't keep up.
    private func ease(_ t: Double) -> Double {
        isFast ? 1 - pow(1 - t, 3) : t * t * (3 - 2 * t)
    }
}
