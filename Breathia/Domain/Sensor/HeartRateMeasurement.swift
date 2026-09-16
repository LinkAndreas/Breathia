import Foundation

struct HeartRateMeasurement: Equatable {
    let heartRate: Int
    /// Beat-to-beat intervals in milliseconds.
    let rrIntervals: [Double]
    /// `false` when the sensor reports it has lost contact with the skin — its
    /// readings are then meaningless. `true` for sensors that don't report contact.
    var hasSkinContact = true

    /// Whether the reading describes a real heartbeat.
    var isValid: Bool { hasSkinContact && heartRate > 0 }
}
