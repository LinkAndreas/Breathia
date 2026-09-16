import Foundation

/// Heart-rate variability over a window of recent beats, in milliseconds.
struct HRV: Equatable {
    /// Standard deviation of the beat-to-beat intervals.
    let sdnn: Double
    /// Root mean square of successive differences between beats.
    let rmssd: Double
}
