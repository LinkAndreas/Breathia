import Foundation

/// Decides when to ask whether the user enjoys the app, and acts on the answer:
/// "yes" requests the App Store rating dialog, "no" opens a feedback email to
/// support. `RatingFlow` asks the question and presents the answers.
final class ReviewPrompter {
    private let repository: ReviewPromptRepository
    private let reviewRequester: ReviewRequesting
    private let mailer: FeedbackMailing
    private let metadataProvider: AppMetadataProviding
    private let policy: ReviewPromptPolicy

    init(
        repository: ReviewPromptRepository,
        reviewRequester: ReviewRequesting,
        mailer: FeedbackMailing,
        metadataProvider: AppMetadataProviding,
        policy: ReviewPromptPolicy = ReviewPromptPolicy()
    ) {
        self.repository = repository
        self.reviewRequester = reviewRequester
        self.mailer = mailer
        self.metadataProvider = metadataProvider
        self.policy = policy
    }

    func shouldAsk(completedSessions: Int) -> Bool {
        policy.shouldAsk(completedSessions: completedSessions, hasAsked: repository.hasAsked)
    }

    /// Records that the question was shown, so it's never asked again.
    func markAsked() {
        repository.markAsked()
    }

    func userEnjoysApp() {
        reviewRequester.requestReview()
    }

    /// Opens a feedback email with the app and device details at the bottom.
    /// Returns `false` when no mail app could open it.
    func userDoesNotEnjoyApp() async -> Bool {
        let email = FeedbackEmail(
            subject: String(localized: "rating.feedbackEmail.breathiaFeedback"),
            prompt: String(localized: "rating.feedbackEmail.whatCouldWeDo"),
            metadata: metadataProvider.metadata
        )
        return await mailer.compose(email)
    }
}
