import Foundation

/// What the onboarding's Apple Health step can do. Provided by the app layer, so
/// the onboarding screens stay unaware of HealthKit.
struct HealthAccessStep {
    /// Where the step starts: `.allowed` when onboarding is shown again after the
    /// user already chose to save mindful minutes, otherwise `.undecided`.
    let initialState: HealthAccessState
    /// Shows the system Health permission sheet and returns whether saving
    /// mindful minutes is allowed. Updates the app's setting accordingly.
    let requestAccess: @MainActor () async -> Bool
    /// The user chose not to save mindful minutes.
    let decline: @MainActor () -> Void
}

enum HealthAccessState: Equatable {
    case undecided
    case requesting
    case allowed
    case declined

    var isPending: Bool { self == .undecided || self == .requesting }
}
