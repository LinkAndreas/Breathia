import Foundation

/// Whether the app may save mindful minutes to Apple Health.
enum HealthAccess: Equatable {
    /// The device has no Health app, such as some iPads.
    case unavailable
    case notDetermined
    case allowed
    case denied
}

/// Saves finished sessions to Apple Health as mindful minutes. Implemented with
/// HealthKit in Infrastructure, so stores and screens never see HealthKit types.
protocol MindfulMinutesService {
    var access: HealthAccess { get }
    /// Shows the system permission sheet if the user hasn't decided yet, and
    /// returns the resulting access.
    func requestAccess() async -> HealthAccess
    func save(_ session: SessionRecord) async throws
}
