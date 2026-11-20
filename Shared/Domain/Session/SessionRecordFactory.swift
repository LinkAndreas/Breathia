import Foundation

/// Condenses the raw samples of a finished session into a `SessionRecord`.
enum SessionRecordFactory {
    static let maximumTracePoints = 120
    /// One reading a second for a quarter of an hour; longer sessions are averaged.
    static let maximumTimelinePoints = 900

    static func makeRecord(
        technique: Technique,
        startedAt: Date,
        duration: TimeInterval,
        heartRates: [Int],
        hrvValues: [Double],
        heartRateTimes: [Int] = [],
        hrvTimes: [Int] = [],
        metric: HRVMetric,
        source: SessionSource
    ) -> SessionRecord {
        let rates = heartRates.map(Double.init)
        let rateTimes = times(heartRateTimes, count: rates.count)
        let heartRateTimeline = rates.isEmpty ? nil : SessionTimeline(times: rateTimes, values: rates)
        let hrvTimeline = hrvValues.isEmpty ? nil : SessionTimeline(times: times(hrvTimes, count: hrvValues.count), values: hrvValues)
        let swings = BreathSwing.swings(times: rateTimes, heartRates: rates, cycleLength: technique.cycleDuration)

        let heartRate: HeartRateStats? = if let first = heartRates.first, let last = heartRates.last {
            HeartRateStats(
                start: first,
                average: Int((Double(heartRates.reduce(0, +)) / Double(heartRates.count)).rounded()),
                end: last
            )
        } else {
            nil
        }

        let hrv: HRVStats? = hrvValues.isEmpty ? nil : HRVStats(
            metric: metric,
            average: hrvValues.reduce(0, +) / Double(hrvValues.count),
            trend: HRVTrend(samples: hrvValues)
        )

        return SessionRecord(
            id: UUID(),
            date: startedAt,
            techniqueID: technique.id,
            duration: duration,
            heartRate: heartRate,
            hrv: hrv,
            heartRateTrace: downsample(rates, to: maximumTracePoints),
            source: source,
            heartRateTimeline: heartRateTimeline?.downsampled(to: maximumTimelinePoints),
            hrvTimeline: hrvTimeline?.downsampled(to: maximumTimelinePoints),
            breathSwings: swings.isEmpty ? nil : swings
        )
    }

    /// The seconds the samples were taken at; one a second from the start when
    /// they weren't recorded.
    private static func times(_ seconds: [Int], count: Int) -> [Double] {
        seconds.count == count ? seconds.map(Double.init) : (0..<count).map(Double.init)
    }

    /// Averages consecutive buckets so long sessions keep a chart-sized trace.
    static func downsample(_ values: [Double], to limit: Int) -> [Double] {
        guard values.count > limit, limit > 0 else { return values }
        let bucketSize = Double(values.count) / Double(limit)
        return (0..<limit).map { bucket in
            let lower = Int(Double(bucket) * bucketSize)
            let upper = max(lower + 1, Int(Double(bucket + 1) * bucketSize))
            let slice = values[lower..<min(upper, values.count)]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }
}
