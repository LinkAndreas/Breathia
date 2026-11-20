import Foundation

/// Conversion between the persisted entity and the domain's `SessionRecord`.
/// Nothing outside Infrastructure sees `SessionEntity`.
extension SessionEntity {
    convenience init(record: SessionRecord) {
        self.init(
            id: record.id,
            date: record.date,
            techniqueID: record.techniqueID,
            duration: record.duration,
            heartRateStart: record.heartRate?.start,
            heartRateAverage: record.heartRate?.average,
            heartRateEnd: record.heartRate?.end,
            hrvMetric: record.hrv?.metric.rawValue,
            hrvAverage: record.hrv?.average,
            hrvTrend: record.hrv?.trend?.rawValue,
            heartRateTrace: record.heartRateTrace,
            source: record.source?.rawValue,
            heartRateTimes: record.heartRateTimeline?.times,
            heartRateValues: record.heartRateTimeline?.values,
            hrvTimes: record.hrvTimeline?.times,
            hrvValues: record.hrvTimeline?.values,
            breathSwings: record.breathSwings
        )
    }

    var record: SessionRecord {
        let heartRate: HeartRateStats? =
            if let heartRateStart, let heartRateAverage, let heartRateEnd {
                HeartRateStats(start: heartRateStart, average: heartRateAverage, end: heartRateEnd)
            } else {
                nil
            }

        let hrv: HRVStats? =
            if let hrvAverage, let metric = hrvMetric.flatMap(HRVMetric.init(rawValue:)) {
                HRVStats(metric: metric, average: hrvAverage, trend: hrvTrend.flatMap(HRVTrend.init(rawValue:)))
            } else {
                nil
            }

        return SessionRecord(
            id: id,
            date: date,
            techniqueID: techniqueID,
            duration: duration,
            heartRate: heartRate,
            hrv: hrv,
            heartRateTrace: heartRateTrace,
            source: source.flatMap(SessionSource.init(rawValue:)),
            heartRateTimeline: Self.timeline(times: heartRateTimes, values: heartRateValues),
            hrvTimeline: Self.timeline(times: hrvTimes, values: hrvValues),
            breathSwings: breathSwings
        )
    }

    private static func timeline(times: [Double]?, values: [Double]?) -> SessionTimeline? {
        guard let times, let values, !values.isEmpty else { return nil }
        return SessionTimeline(times: times, values: values)
    }
}
