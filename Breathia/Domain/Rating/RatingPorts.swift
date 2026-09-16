import Foundation

// Contracts the rating flow depends on. Implementations live in Infrastructure.

/// Remembers whether the user was already asked if they enjoy the app.
protocol ReviewPromptRepository {
    var hasAsked: Bool { get }
    func markAsked()
}

/// Shows the system's App Store rating dialog. The system decides whether it
/// actually appears, so callers must not rely on it.
protocol ReviewRequesting {
    func requestReview()
}

/// Opens a prepared email in the user's mail app.
protocol FeedbackMailing {
    /// Returns `false` when no mail app could open it.
    func compose(_ email: FeedbackEmail) async -> Bool
}

protocol AppMetadataProviding {
    var metadata: AppMetadata { get }
}
