import Foundation

/// Values measured during a session, each with the moment it was taken, for the
/// detailed charts in a session's report.
struct SessionTimeline: Codable, Hashable {
    /// Seconds into the session; paused time doesn't count.
    let times: [Double]
    let values: [Double]

    init(times: [Double], values: [Double]) {
        let count = min(times.count, values.count)
        self.times = Array(times.prefix(count))
        self.values = Array(values.prefix(count))
    }

    struct Point: Hashable, Identifiable {
        let time: Double
        let value: Double
        var id: Double { time }
    }

    var points: [Point] {
        zip(times, values).map { Point(time: $0, value: $1) }
    }

    var isEmpty: Bool { values.isEmpty }

    var average: Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    /// The lowest value and when it was measured; the first one if it repeats.
    var lowest: Point? { points.min { $0.value < $1.value } }

    /// The highest value and when it was measured; the first one if it repeats.
    var highest: Point? { points.max { $0.value < $1.value } }

    /// The trend: each value averaged with those within `window` seconds around it,
    /// which evens out the rise and fall of every breath.
    func smoothed(over window: Double) -> SessionTimeline {
        guard window > 0, values.count > 2 else { return self }
        let half = window / 2
        var lower = 0
        var upper = 0
        var sum = 0.0
        var smoothed: [Double] = []
        smoothed.reserveCapacity(values.count)
        for time in times {
            while upper < times.count, times[upper] < time + half {
                sum += values[upper]
                upper += 1
            }
            while times[lower] < time - half {
                sum -= values[lower]
                lower += 1
            }
            smoothed.append(sum / Double(upper - lower))
        }
        return SessionTimeline(times: times, values: smoothed)
    }

    /// Averages neighbouring points so a long session keeps a chart-sized timeline.
    func downsampled(to limit: Int) -> SessionTimeline {
        guard values.count > limit, limit > 0 else { return self }
        let bucketSize = Double(values.count) / Double(limit)
        var times: [Double] = []
        var values: [Double] = []
        for bucket in 0..<limit {
            let lower = Int(Double(bucket) * bucketSize)
            let upper = min(self.values.count, max(lower + 1, Int(Double(bucket + 1) * bucketSize)))
            let count = Double(upper - lower)
            times.append(self.times[lower..<upper].reduce(0, +) / count)
            values.append(self.values[lower..<upper].reduce(0, +) / count)
        }
        return SessionTimeline(times: times, values: values)
    }
}
