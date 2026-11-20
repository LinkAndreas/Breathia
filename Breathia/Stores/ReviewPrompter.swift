import Foundation

/// Decides when to request the App Store rating dialog and remembers when it
/// did, and prepares the feedback email. `RatingFlow` acts on its answers.
final class ReviewPrompter {
    private let repository: ReviewPromptRepository
    private let mailer: FeedbackMailing
    private let metadataProvider: AppMetadataProviding
    private let policy: ReviewPromptPolicy
    private let now: () -> Date

    init(
        repository: ReviewPromptRepository,
        mailer: FeedbackMailing,
        metadataProvider: AppMetadataProviding,
        policy: ReviewPromptPolicy = ReviewPromptPolicy(),
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.mailer = mailer
        self.metadataProvider = metadataProvider
        self.policy = policy
        self.now = now
    }

    private var appVersion: String { metadataProvider.metadata.appVersion }

    func shouldRequestReview(after session: SessionRecord, sessions: [SessionRecord]) -> Bool {
        policy.shouldRequestReview(
            after: session,
            sessions: sessions,
            appVersion: appVersion,
            history: repository.history,
            now: now()
        )
    }

    /// Records that the dialog was requested. The system may still not show it.
    func recordRequest() {
        repository.recordRequest(version: appVersion, date: now())
    }

    /// Opens a feedback email with the app and device details at the bottom.
    /// Returns `false` when no mail app could open it.
    func sendFeedback() async -> Bool {
        let email = FeedbackEmail(
            subject: String(localized: "rating.feedbackEmail.breathiaFeedback"),
            prompt: String(localized: "rating.feedbackEmail.whatCouldWeDo"),
            metadata: metadataProvider.metadata
        )
        return await mailer.compose(email)
    }
}
