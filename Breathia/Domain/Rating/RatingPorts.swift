import Foundation

// Contracts the rating flow depends on. Implementations live in Infrastructure.

/// Remembers when the App Store rating dialog was last requested.
protocol ReviewPromptRepository {
    var history: ReviewPromptHistory { get }
    func recordRequest(version: String, date: Date)
}

/// Opens a prepared email in the user's mail app.
protocol FeedbackMailing {
    /// Returns `false` when no mail app could open it.
    func compose(_ email: FeedbackEmail) async -> Bool
}

protocol AppMetadataProviding {
    var metadata: AppMetadata { get }
}
