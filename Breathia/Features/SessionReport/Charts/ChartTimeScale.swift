import Foundation

/// Where a session chart's time axis gets its labels: about four to six round
/// steps — every 30 seconds for a short session, every few minutes for a long one.
enum ChartTimeScale {
    static func ticks(for duration: TimeInterval) -> [Double] {
        let steps: [Double] = [15, 30, 60, 120, 180, 300, 600, 900, 1_800]
        let step = steps.first { duration / $0 <= 5 } ?? 3_600
        return Array(stride(from: 0, through: duration, by: step))
    }
}
