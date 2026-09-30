import Foundation
import Testing
@testable import Breathia

struct BreathCueTests {
    @Test func aPhaseWithoutCuesShowsNone() {
        #expect(BreathPhase.exhale(4).cue(inCycle: 1) == nil)
    }

    @Test func aSingleCueShowsEveryCycle() {
        let phase = BreathPhase.exhale(6, cue: .hum)
        #expect(phase.cue(inCycle: 1) == .hum)
        #expect(phase.cue(inCycle: 7) == .hum)
    }

    @Test func severalCuesTakeTurnsCycleByCycle() {
        let phase = BreathPhase.inhale(4, cue: .leftNostril, .rightNostril)
        #expect(phase.cue(inCycle: 1) == .leftNostril)
        #expect(phase.cue(inCycle: 2) == .rightNostril)
        #expect(phase.cue(inCycle: 3) == .leftNostril)
    }

    @Test func theClockReportsTheCueOfThePhaseAndCycle() {
        let clock = BreathingClock(technique: .testTechnique(phases: [
            .inhale(4, cue: .leftNostril, .rightNostril), .hold(2, scale: 1.15), .exhale(4, cue: .rightNostril, .leftNostril),
        ]))
        #expect(clock.position(at: 1).cue == .leftNostril)
        #expect(clock.position(at: 5).cue == nil)
        #expect(clock.position(at: 7).cue == .rightNostril)
        #expect(clock.position(at: 11).cue == .rightNostril)
        #expect(clock.position(at: 17).cue == .leftNostril)
    }

    @Test func aTechniqueListsEachCueOnce() {
        let technique = Technique.testTechnique(phases: [.inhale(1, cue: .throughNose), .exhale(1, cue: .throughNose), .hold(1, scale: 1, cue: .relaxJaw)])
        #expect(technique.cues == [.throughNose, .relaxJaw])
    }

    /// A cue whose key is missing from the string catalog would show the raw key.
    @Test func everyCueInTheCatalogIsLocalized() {
        for cue in TechniqueCatalog.all.flatMap(\.cues) {
            #expect(cue.text != cue.id)
        }
    }
}
