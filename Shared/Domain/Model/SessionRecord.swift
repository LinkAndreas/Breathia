import Foundation

struct HeartRateStats: Codable, Hashable {
    let start: Int
    let average: Int
    let end: Int
}

struct HRVStats: Codable, Hashable {
    let metric: HRVMetric
    let average: Double
    let trend: HRVTrend?
}

enum SessionSource: String, Codable, Hashable {
    case iPhone, watch, mac
}

/// A finished breathing session as stored in History. Summary statistics are
/// computed once when the session ends; only a downsampled heart-rate trace is kept
/// for the chart.
struct SessionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let techniqueID: Technique.ID
    /// Active (un-paused) duration in seconds.
    let duration: TimeInterval
    let heartRate: HeartRateStats?
    let hrv: HRVStats?
    let heartRateTrace: [Double]
    /// The device the session was performed on.
    let source: SessionSource?

    var technique: Technique { TechniqueCatalog.technique(withID: techniqueID) }
    var hasSensorData: Bool { heartRate != nil }
}

enum HRVTrend: String, Codable, Hashable {
    case increasing, stable, decreasing

    /// Compares the second half of a session against the first; a change of less
    /// than 5% either way counts as stable.
    init?(samples: [Double]) {
        guard samples.count >= 4 else { return nil }
        let half = samples.count / 2
        let first = samples.prefix(half).reduce(0, +) / Double(half)
        let second = samples.suffix(samples.count - half).reduce(0, +) / Double(samples.count - half)
        guard first > 0 else { return nil }

        let ratio = second / first
        if ratio > 1.05 {
            self = .increasing
        } else if ratio < 0.95 {
            self = .decreasing
        } else {
            self = .stable
        }
    }
}
