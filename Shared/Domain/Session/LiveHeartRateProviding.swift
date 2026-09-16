import Foundation

/// The live readings a breathing session samples. Implemented by the Polar H10
/// monitor on iPhone and by the workout session on Apple Watch, so the session
/// logic itself is the same on both devices.
protocol LiveHeartRateProviding: AnyObject {
    var isConnected: Bool { get }
    var heartRate: Int? { get }
    /// `nil` when the source can't deliver beat-to-beat intervals.
    var hrv: HRV? { get }
}
