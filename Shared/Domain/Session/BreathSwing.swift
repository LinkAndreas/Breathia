import Foundation

/// How much the heart rate rose and fell within each breath.
///
/// Breathing in speeds the heart up and breathing out slows it down (respiratory
/// sinus arrhythmia). The swing — the highest minus the lowest heart rate within
/// one breath — grows when slow breathing and the heart rhythm fall in step,
/// which is what resonance breathing aims for.
enum BreathSwing {
    /// The swing of every whole breath, in beats per minute. A breath counts only
    /// if the sensor measured most of it.
    ///
    /// - Parameters:
    ///   - times: Seconds into the session of each heart-rate reading.
    ///   - heartRates: The readings, about one a second.
    ///   - cycleLength: The length of one breath in seconds.
    static func swings(times: [Double], heartRates: [Double], cycleLength: Int) -> [Double] {
        guard cycleLength > 0, !times.isEmpty else { return [] }
        let length = Double(cycleLength)
        let needed = max(2, Int((length * 0.6).rounded(.down)))
        var breaths: [Int: [Double]] = [:]
        for (time, rate) in zip(times, heartRates) {
            breaths[Int(time / length), default: []].append(rate)
        }
        // A breath still under way when the session ended is left out.
        let lastWhole = Int(((times.last ?? 0) + 1) / length) - 1
        guard lastWhole >= 0 else { return [] }
        return (0...lastWhole).compactMap { breath in
            guard let rates = breaths[breath], rates.count >= needed,
                  let low = rates.min(), let high = rates.max() else { return nil }
            return high - low
        }
    }
}

extension BreathSwing {
    /// What the swings of a session add up to.
    struct Summary: Equatable {
        let average: Double
        let largest: Double
        let breaths: Int
        /// Whether the swings grew clearly from the first third of the session to
        /// the last — a sign the breathing and heart fell into step.
        let grew: Bool
    }

    /// `nil` with fewer than three breaths, too few to say anything about.
    static func summary(of swings: [Double]) -> Summary? {
        guard swings.count >= 3, let largest = swings.max() else { return nil }
        let average = swings.reduce(0, +) / Double(swings.count)
        let third = max(1, swings.count / 3)
        let early = swings.prefix(third).reduce(0, +) / Double(third)
        let late = swings.suffix(third).reduce(0, +) / Double(third)
        let grew = late >= early * 1.25 && late - early >= 1.5
        return Summary(average: average, largest: largest, breaths: swings.count, grew: grew)
    }
}
