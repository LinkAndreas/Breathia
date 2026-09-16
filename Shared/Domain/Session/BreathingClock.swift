import Foundation

/// Maps elapsed session time onto a technique's repeating phase pattern.
/// Pure and deterministic, so the breathing circle can sample it every frame.
struct BreathingClock {
    struct Position: Equatable {
        let phaseIndex: Int
        let phase: BreathPhase
        /// 1-based cycle number.
        let cycle: Int
        /// Whole seconds left in the current phase, counting down to 1.
        let secondsRemaining: Int
        /// The number shown in the circle: counting up (1…N) while breathing in and
        /// holding, and down (N…1) while breathing out, as the circle empties.
        /// Consecutive phases of the same kind count as one breath, so a top-up inhale
        /// carries on from the one before.
        let count: Int
        /// How far through the current phase, from 0 at its start to 1 at its end.
        let phaseProgress: Double
        /// Circle scale, eased from the previous phase's scale to this one's.
        let scale: Double

        var countsDown: Bool { phase.kind == .exhale }
    }

    let phases: [BreathPhase]

    init(technique: Technique) {
        phases = technique.phases
    }

    func position(at elapsed: TimeInterval) -> Position {
        let cycleLength = Double(phases.reduce(0) { $0 + $1.seconds })
        guard cycleLength > 0 else {
            return Position(phaseIndex: 0, phase: phases[0], cycle: 1, secondsRemaining: 0, count: 0, phaseProgress: 0, scale: 1)
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
                    count: count(inPhaseAt: index, offset: min(offset, length)),
                    phaseProgress: progress,
                    scale: previous.scale + (phase.scale - previous.scale) * Self.ease(progress)
                )
            }
            offset -= length
        }
        preconditionFailure("unreachable: the last phase always matches")
    }

    /// The circle's number `offset` seconds into phase `index` — see `Position.count`.
    private func count(inPhaseAt index: Int, offset: TimeInterval) -> Int {
        // The breath: this phase and the phases of the same kind right before and after it.
        let kind = phases[index].kind
        var first = index
        while first > 0, phases[first - 1].kind == kind { first -= 1 }
        var last = index
        while last < phases.count - 1, phases[last + 1].kind == kind { last += 1 }

        let breathLength = phases[first...last].reduce(0) { $0 + $1.seconds }
        let intoBreath = Double(phases[first..<index].reduce(0) { $0 + $1.seconds }) + offset
        if kind == .exhale {
            // N during the first second, 1 during the last.
            return Self.secondsLeft(of: Double(breathLength), after: intoBreath)
        }
        // 1 during the first second, N during the last.
        return min(breathLength, Int(intoBreath) + 1)
    }

    /// Whole seconds left, counting down to 1 (never 0 while the span lasts).
    private static func secondsLeft(of length: TimeInterval, after offset: TimeInterval) -> Int {
        max(1, Int((length - offset).rounded(.up)))
    }

    /// Smoothstep — breaths start and finish gently rather than at constant speed.
    private static func ease(_ t: Double) -> Double {
        t * t * (3 - 2 * t)
    }
}
