import Foundation

/// Computes HRV metrics over a rolling window of RR intervals. A value type, so
/// each monitor owns its own window and can reset it when the sensor disconnects.
///
/// Intervals are screened before they enter the window: a missed or extra beat —
/// common whenever a chest strap shifts — would otherwise inflate RMSSD several-fold
/// and turn live feedback and the session's statistics into noise.
struct HRVCalculator {
    /// Rolling window — the last ~100 beats (~1–2 min depending on heart rate).
    static let capacity = 100
    /// Physiologically plausible RR intervals (200–30 bpm).
    static let plausibleInterval: ClosedRange<Double> = 300...2000
    /// Largest accepted change from the previous beat (Malik's criterion).
    static let maximumRelativeChange = 0.2
    /// After this many rejections in a row the rhythm has really changed, so the
    /// next plausible interval becomes the new reference instead of being rejected.
    static let rejectionsBeforeReset = 3

    private var rrBuffer: [Double] = []
    private var consecutiveRejections = 0

    mutating func reset() {
        rrBuffer.removeAll()
        consecutiveRejections = 0
    }

    /// Adds `rrIntervals` (milliseconds) and returns HRV over the window, or `nil`
    /// until it holds at least two beats.
    mutating func calculate(from rrIntervals: [Double]) -> HRV? {
        for interval in rrIntervals {
            accept(interval)
        }
        if rrBuffer.count > Self.capacity {
            rrBuffer.removeFirst(rrBuffer.count - Self.capacity)
        }
        guard rrBuffer.count >= 2 else { return nil }

        let mean = rrBuffer.reduce(0, +) / Double(rrBuffer.count)
        let variance = rrBuffer.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(rrBuffer.count)

        let squaredDifferences = zip(rrBuffer.dropFirst(), rrBuffer).map { ($0 - $1) * ($0 - $1) }
        let meanSquaredDifference = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)

        return HRV(sdnn: variance.squareRoot(), rmssd: meanSquaredDifference.squareRoot())
    }

    private mutating func accept(_ interval: Double) {
        guard Self.plausibleInterval.contains(interval) else { return }

        if let previous = rrBuffer.last,
           consecutiveRejections < Self.rejectionsBeforeReset,
           abs(interval - previous) / previous > Self.maximumRelativeChange {
            consecutiveRejections += 1
            return
        }
        consecutiveRejections = 0
        rrBuffer.append(interval)
    }
}
