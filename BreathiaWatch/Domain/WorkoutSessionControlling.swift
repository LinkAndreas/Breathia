import Foundation

/// A workout on Apple Watch: supplies live heart rate while it runs and keeps the
/// app in front for the length of a breathing session. Implemented with HealthKit
/// by `WorkoutHeartRateProvider`.
protocol WorkoutSessionControlling: LiveHeartRateProviding {
    /// Whether asking for access would show the Health permission sheet — so the
    /// app can explain why first.
    var needsAuthorization: Bool { get }
    /// Asks once for the Health access the watch app needs.
    func requestAuthorization() async
    func start() async
    /// Ends the workout, saving it to Health or discarding it. Safe to call more
    /// than once — only the first call after `start` does anything.
    func stop(save: Bool) async
}
