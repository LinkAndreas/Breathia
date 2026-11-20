import Foundation
import SwiftData
import Testing
@testable import Breathia

struct BreathSwingTests {
    /// A heart rate that rises and falls by `swing` once per `cycle` seconds.
    private func oscillating(seconds: Int, cycle: Int, swing: Double) -> (times: [Double], rates: [Double]) {
        let times = (0..<seconds).map(Double.init)
        let rates = times.map { 65 + swing / 2 * sin(2 * .pi * $0 / Double(cycle)) }
        return (times, rates)
    }

    @Test func measuresTheRiseAndFallOfEachBreath() {
        let (times, rates) = oscillating(seconds: 100, cycle: 10, swing: 8)
        let swings = BreathSwing.swings(times: times, heartRates: rates, cycleLength: 10)
        #expect(swings.count == 10)
        for swing in swings {
            #expect(abs(swing - 8) < 1)
        }
    }

    @Test func leavesOutABreathStillUnderWay() {
        let (times, rates) = oscillating(seconds: 95, cycle: 10, swing: 6)
        #expect(BreathSwing.swings(times: times, heartRates: rates, cycleLength: 10).count == 9)
    }

    @Test func skipsABreathTheSensorMostlyMissed() {
        var (times, rates) = oscillating(seconds: 40, cycle: 10, swing: 6)
        // The sensor drops out for most of the second breath.
        let kept = times.indices.filter { !(12...19).contains(Int(times[$0])) }
        times = kept.map { times[$0] }
        rates = kept.map { rates[$0] }
        #expect(BreathSwing.swings(times: times, heartRates: rates, cycleLength: 10).count == 3)
    }

    @Test func summarisesTheSwings() throws {
        let summary = try #require(BreathSwing.summary(of: [3, 3, 4, 5, 7, 8]))
        #expect(summary.largest == 8)
        #expect(summary.breaths == 6)
        #expect(abs(summary.average - 5) < 0.01)
        #expect(summary.grew)

        let flat = try #require(BreathSwing.summary(of: [5, 5, 5, 5, 5, 5]))
        #expect(!flat.grew)
        #expect(BreathSwing.summary(of: [5, 6]) == nil)
    }
}

struct SessionTimelineTests {
    @Test func keepsEachReadingWithItsTime() {
        let record = SessionRecordFactory.makeRecord(
            technique: .testTechnique(phases: [.inhale(5), .exhale(5)], duration: 60),
            startedAt: .now, duration: 60,
            heartRates: [70, 71, 69], hrvValues: [40, 42],
            heartRateTimes: [0, 1, 5], hrvTimes: [3, 4],
            metric: .rmssd, source: .iPhone
        )
        #expect(record.heartRateTimeline?.times == [0, 1, 5])
        #expect(record.heartRateTimeline?.values == [70, 71, 69])
        #expect(record.hrvTimeline?.times == [3, 4])
    }

    @Test func averagesALongSessionIntoAChartSizedTimeline() {
        let timeline = SessionTimeline(times: (0..<3_600).map(Double.init), values: (0..<3_600).map { Double($0 % 60) })
        let small = timeline.downsampled(to: 900)
        #expect(small.values.count == 900)
        #expect(small.times.first == 1.5)
        #expect(small.times.last == 3_597.5)
    }

    @Test func theTrendEvensOutEachBreath() {
        let times = (0..<120).map(Double.init)
        // Settling from 70 to 58, rising and falling by 8 with each 10-second breath.
        let values = times.map { 70 - $0 / 10 + 4 * sin(2 * .pi * $0 / 10) }
        let trend = SessionTimeline(times: times, values: values).smoothed(over: 20)
        // Away from the edges, the trend follows the settling, not the breaths.
        for index in 20..<100 {
            #expect(abs(trend.values[index] - (70 - times[index] / 10)) < 0.6)
        }
    }

    @Test func findsTheLowestAndHighestMoment() {
        let timeline = SessionTimeline(times: [0, 10, 20, 30], values: [70, 61, 66, 74])
        #expect(timeline.lowest == SessionTimeline.Point(time: 10, value: 61))
        #expect(timeline.highest == SessionTimeline.Point(time: 30, value: 74))
    }

    @Test func anOlderSessionStillGetsAChartFromItsTrace() {
        let record = SessionRecord(
            id: UUID(), date: .now, techniqueID: "box", duration: 120,
            heartRate: HeartRateStats(start: 70, average: 66, end: 62), hrv: nil,
            heartRateTrace: [70, 66, 62], source: .iPhone
        )
        #expect(record.heartRatePoints.map(\.time) == [0, 60, 120])
    }

    @Test func describesTheHeartRateInWords() {
        func record(_ start: Int, _ end: Int) -> SessionRecord {
            SessionRecord(
                id: UUID(), date: .now, techniqueID: "box", duration: 60,
                heartRate: HeartRateStats(start: start, average: (start + end) / 2, end: end), hrv: nil,
                heartRateTrace: [], source: .iPhone
            )
        }
        #expect(record(72, 60).heartRateSummary != record(60, 72).heartRateSummary)
        #expect(record(66, 67).heartRateSummary == String(localized: "report.heartRate.steady \(66)"))
    }
}

@MainActor
struct HistoryStorageTests {
    @Test func storesTheTimelinesAndSwings() throws {
        let repository = SwiftDataSessionRepository(container: try HistoryDatabase.makeContainer(isStoredInMemoryOnly: true))
        let record = PreviewData.sessions[0]
        try repository.insert(record)
        let stored = try #require(try repository.fetchAll().first)
        #expect(stored.heartRateTimeline == record.heartRateTimeline)
        #expect(stored.hrvTimeline == record.hrvTimeline)
        #expect(stored.breathSwings == record.breathSwings)
    }
}
