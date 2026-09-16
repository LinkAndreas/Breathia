import Foundation
import Testing
@testable import Breathia

struct SessionRecordTests {
    @Test func summarizesHeartRateAndHRV() throws {
        let record = SessionRecordFactory.makeRecord(
            technique: .testTechnique(phases: [.inhale(4), .exhale(4)]),
            startedAt: Date(timeIntervalSince1970: 0),
            duration: 60,
            heartRates: [70, 66, 62],
            hrvValues: [40, 40, 60, 60],
            metric: .rmssd,
            source: .iPhone
        )
        #expect(record.heartRate == HeartRateStats(start: 70, average: 66, end: 62))
        let hrv = try #require(record.hrv)
        #expect(hrv.average == 50)
        #expect(hrv.trend == .increasing)
        #expect(record.hasSensorData)
    }

    @Test func hasNoStatisticsWithoutSamples() {
        let record = SessionRecordFactory.makeRecord(
            technique: .testTechnique(phases: [.inhale(4)]),
            startedAt: .now, duration: 30, heartRates: [], hrvValues: [], metric: .sdnn, source: .watch
        )
        #expect(record.heartRate == nil)
        #expect(record.hrv == nil)
        #expect(!record.hasSensorData)
    }

    @Test func downsamplesLongTraces() {
        let trace = SessionRecordFactory.downsample((0..<600).map(Double.init), to: 120)
        #expect(trace.count == 120)
        #expect(trace.first == 2)
    }

    @Test func trendNeedsEnoughSamples() {
        #expect(HRVTrend(samples: [1, 2, 3]) == nil)
        #expect(HRVTrend(samples: [50, 50, 49, 51]) == .stable)
        #expect(HRVTrend(samples: [60, 60, 40, 40]) == .decreasing)
    }
}
