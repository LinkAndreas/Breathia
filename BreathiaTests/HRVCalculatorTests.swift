import Foundation
import Testing
@testable import Breathia

struct HRVCalculatorTests {
    @Test func needsTwoBeats() {
        var calculator = HRVCalculator()
        #expect(calculator.calculate(from: [800]) == nil)
        #expect(calculator.calculate(from: [810]) != nil)
    }

    @Test func computesRMSSDAndSDNN() throws {
        var calculator = HRVCalculator()
        let result = calculator.calculate(from: [800, 840, 800, 840])
        let hrv = try #require(result)
        #expect(abs(hrv.rmssd - 40) < 0.001)
        #expect(abs(hrv.sdnn - 20) < 0.001)
    }

    @Test func rejectsImplausibleIntervals() throws {
        var calculator = HRVCalculator()
        let result = calculator.calculate(from: [800, 150, 2500, 820])
        let hrv = try #require(result)
        #expect(abs(hrv.rmssd - 20) < 0.001)
    }

    /// A missed beat doubles one interval; kept, it would inflate RMSSD several-fold.
    @Test func rejectsAMissedBeat() throws {
        var calculator = HRVCalculator()
        let result = calculator.calculate(from: [800, 810, 1610, 820, 810])
        let hrv = try #require(result)
        #expect(hrv.rmssd < 15)
    }

    @Test func followsARealChangeInRhythm() throws {
        var calculator = HRVCalculator()
        _ = calculator.calculate(from: [1000, 1000])
        // Three rejections, then the new rhythm is accepted.
        let result = calculator.calculate(from: [600, 600, 600, 600, 600])
        let hrv = try #require(result)
        #expect(hrv.rmssd > 0)
        #expect(calculator.calculate(from: [605]) != nil)
    }

    @Test func keepsARollingWindow() throws {
        var calculator = HRVCalculator()
        _ = calculator.calculate(from: (0..<200).map { $0.isMultiple(of: 2) ? 800 : 900 })
        let result = calculator.calculate(from: [800, 800])
        let hrv = try #require(result)
        #expect(hrv.rmssd > 0)
    }

    @Test func resetForgetsTheWindow() {
        var calculator = HRVCalculator()
        _ = calculator.calculate(from: [800, 810, 820])
        calculator.reset()
        #expect(calculator.calculate(from: [800]) == nil)
    }
}
