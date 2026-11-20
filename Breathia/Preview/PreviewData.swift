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
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let source: SessionSource = daysAgo == 3 ? .watch : .iPhone
        let technique = TechniqueCatalog.technique(withID: technique)
        guard !trace.isEmpty else {
            return SessionRecord(
                id: UUID(), date: date, techniqueID: technique.id, duration: duration,
                heartRate: nil, hrv: nil, heartRateTrace: [], source: source
            )
        }

        // One reading a second: the trace's slow settling, plus the rise and fall
        // with each breath, which grows as the session goes on.
        let seconds = Int(duration)
        let cycle = Double(max(1, technique.cycleDuration))
        var heartRates: [Int] = []
        var hrvValues: [Double] = []
        for second in 0..<seconds {
            let progress = Double(second) / Double(max(1, seconds - 1))
            let base = interpolate(trace, at: progress)
            let swing = 2.5 + 3.5 * progress
            let breath = sin(2 * .pi * Double(second) / cycle)
            let wobble = sin(Double(second) * 1.7) * 0.6
            heartRates.append(Int((base + swing * breath + wobble).rounded()))
            if let hrv {
                let change: Double = switch trend {
                case .increasing: 0.3
                case .decreasing: -0.2
                default: 0
                }
                hrvValues.append(hrv * (1 - change / 2 + change * progress) + sin(Double(second) / 9) * 2)
            }
        }
        let made = SessionRecordFactory.makeRecord(
            technique: technique, startedAt: date, duration: duration,
            heartRates: heartRates, hrvValues: hrvValues,
            heartRateTimes: Array(0..<seconds), hrvTimes: hrvValues.isEmpty ? [] : Array(0..<seconds),
            metric: .rmssd, source: source
        )
        return made
    }

    private static func interpolate(_ values: [Double], at progress: Double) -> Double {
        guard values.count > 1 else { return values.first ?? 0 }
        let position = progress * Double(values.count - 1)
        let lower = Int(position)
        let upper = min(values.count - 1, lower + 1)
        let fraction = position - Double(lower)
        return values[lower] + (values[upper] - values[lower]) * fraction
    }
}
#endif
