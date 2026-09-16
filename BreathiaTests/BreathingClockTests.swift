import Foundation
import Testing
@testable import Breathia

struct BreathingClockTests {
    /// The circle's number at the middle of each second of one cycle, prefixed with
    /// the phase: "I" inhale, "H" hold, "E" exhale.
    private func counts(_ phases: [BreathPhase]) -> [String] {
        let clock = BreathingClock(technique: .testTechnique(phases: phases))
        let cycle = phases.reduce(0) { $0 + $1.seconds }
        return (0..<cycle).map { second in
            let position = clock.position(at: Double(second) + 0.5)
            return "\(position.phase.kind.rawValue.prefix(1).uppercased())\(position.count)"
        }
    }

    @Test func countsUpWhileBreathingInAndDownWhileBreathingOut() {
        #expect(counts([.inhale(4), .exhale(4)]) == ["I1", "I2", "I3", "I4", "E4", "E3", "E2", "E1"])
    }

    @Test func holdsCountUp() {
        #expect(counts([.inhale(2), .hold(3, scale: 1.15), .exhale(2)]) == ["I1", "I2", "H1", "H2", "H3", "E2", "E1"])
    }

    @Test func consecutiveInhalesCountAsOneBreath() {
        #expect(counts([.inhale(2, scale: 1), .inhale(1), .exhale(3)]) == ["I1", "I2", "I3", "E3", "E2", "E1"])
    }

    @Test func secondsRemainingCountsDownToOne() {
        let clock = BreathingClock(technique: .testTechnique(phases: [.inhale(4), .exhale(4)]))
        #expect(clock.position(at: 0).secondsRemaining == 4)
        #expect(clock.position(at: 3.99).secondsRemaining == 1)
        #expect(clock.position(at: 4).phase.kind == .exhale)
    }

    @Test func repeatsCyclesAndCountsThem() {
        let clock = BreathingClock(technique: .testTechnique(phases: [.inhale(4), .exhale(4)]))
        let position = clock.position(at: 17)
        #expect(position.cycle == 3)
        #expect(position.phaseIndex == 0)
    }

    @Test func scaleEasesFromThePreviousPhaseToThisOne() {
        let clock = BreathingClock(technique: .testTechnique(phases: [.inhale(4, scale: 1.2), .exhale(4, scale: 0.8)]))
        #expect(clock.position(at: 0).scale == 0.8)
        #expect(abs(clock.position(at: 3.999).scale - 1.2) < 0.001)
    }

    @Test func progressGoesFromZeroToOneWithinAPhase() {
        let clock = BreathingClock(technique: .testTechnique(phases: [.inhale(4), .exhale(4)]))
        #expect(clock.position(at: 0).phaseProgress == 0)
        #expect(clock.position(at: 2).phaseProgress == 0.5)
    }
}

extension Technique {
    static func testTechnique(phases: [BreathPhase], duration: Int = 60) -> Technique {
        Technique(
            id: "test", name: "Test", summary: "", purpose: "", category: .calm,
            isBeginnerFriendly: true, recommendedDuration: duration, phases: phases,
            howItWorks: "", bestFor: [], steps: [], safetyNote: "", hue: 0
        )
    }
}
