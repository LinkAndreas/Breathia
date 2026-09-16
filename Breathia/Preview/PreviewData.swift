// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// Sample sessions for SwiftUI previews.
enum PreviewData {
    static let sessions: [SessionRecord] = [
        record(daysAgo: 1, technique: "resonance", duration: 600, trace: [71, 69, 67, 66, 64, 62, 60, 59, 58, 58], hrv: 52, trend: .increasing),
        record(daysAgo: 3, technique: "box", duration: 300, trace: [74, 72, 70, 69, 68, 67, 66, 65, 65, 65], hrv: 41, trend: .stable),
        record(daysAgo: 5, technique: "478", duration: 240, trace: [76, 75, 74, 72, 71, 70, 70, 69, 69, 69], hrv: 38, trend: .increasing),
        record(daysAgo: 8, technique: "relax", duration: 360, trace: [70, 69, 67, 66, 65, 64, 63, 62, 61, 61], hrv: 47, trend: .increasing),
        record(daysAgo: 11, technique: "equal", duration: 300, trace: [], hrv: nil, trend: nil),
    ]

    private static func record(
        daysAgo: Int,
        technique: Technique.ID,
        duration: TimeInterval,
        trace: [Double],
        hrv: Double?,
        trend: HRVTrend?
    ) -> SessionRecord {
        let heartRate = trace.isEmpty ? nil : HeartRateStats(
            start: Int(trace[0]),
            average: Int((trace.reduce(0, +) / Double(trace.count)).rounded()),
            end: Int(trace[trace.count - 1])
        )
        return SessionRecord(
            id: UUID(),
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now,
            techniqueID: technique,
            duration: duration,
            heartRate: heartRate,
            hrv: hrv.map { HRVStats(metric: .rmssd, average: $0, trend: trend) },
            heartRateTrace: trace,
            source: daysAgo == 3 ? .watch : .iPhone
        )
    }
}
#endif
