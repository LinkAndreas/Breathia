import Foundation

/// Condenses the raw samples of a finished session into a `SessionRecord`.
enum SessionRecordFactory {
    static let maximumTracePoints = 120

    static func makeRecord(
        technique: Technique,
        startedAt: Date,
        duration: TimeInterval,
        heartRates: [Int],
        hrvValues: [Double],
        metric: HRVMetric,
        source: SessionSource
    ) -> SessionRecord {
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
            heartRateTrace: downsample(heartRates.map(Double.init), to: maximumTracePoints),
            source: source
        )
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
