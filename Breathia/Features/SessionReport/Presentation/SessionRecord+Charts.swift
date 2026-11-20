import Foundation

extension SessionRecord {
    /// Heart rate over the session: the timeline, or for a session recorded
    /// before timelines existed, its short trace spread over the session.
    var heartRatePoints: [SessionTimeline.Point] {
        if let heartRateTimeline, !heartRateTimeline.isEmpty {
            return heartRateTimeline.points
        }
        guard heartRateTrace.count > 1 else {
            return heartRateTrace.map { SessionTimeline.Point(time: 0, value: $0) }
        }
        let step = duration / Double(heartRateTrace.count - 1)
        return heartRateTrace.enumerated().map { SessionTimeline.Point(time: Double($0) * step, value: $1) }
    }

    /// How the heart rate changed from the start to the end, in one sentence.
    var heartRateSummary: String? {
        guard let heartRate else { return nil }
        let change = heartRate.end - heartRate.start
        if abs(change) < 3 {
            return String(localized: "report.heartRate.steady \(heartRate.average)")
        }
        return change < 0
            ? String(localized: "report.heartRate.settled \(-change) \(heartRate.start) \(heartRate.end)")
            : String(localized: "report.heartRate.rose \(change) \(heartRate.start) \(heartRate.end)")
    }

    var breathSwingSummary: BreathSwing.Summary? {
        breathSwings.flatMap(BreathSwing.summary(of:))
    }
}

/// How a heart rate or HRV value reads in the charts.
enum ReportValueFormat {
    static func bpm(_ value: Double) -> String {
        String(localized: "common.bpm \(Int(value.rounded()))")
    }

    static func milliseconds(_ value: Double) -> String {
        String(localized: "report.milliseconds \(Int(value.rounded()))")
    }
}
