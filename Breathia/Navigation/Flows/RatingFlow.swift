import Foundation

/// Asks for an App Store rating the way Apple recommends, and takes feedback.
///
/// After a recorded session that meets `ReviewPromptPolicy`, and once the session
/// screen has closed and History settled, the system's rating dialog is requested
/// — directly, with no question of our own before it. Feedback by email, rating
/// and sharing are always available in Settings.
final class RatingFlow {
    /// Long enough for the session screen to close and History to settle, so the
    /// dialog comes on a calm screen rather than mid-transition.
    static let delayAfterSession: Duration = .seconds(1.5)

    private let prompter: ReviewPrompter
    private let sessionHistory: SessionHistory
    private let navigator: AppNavigator
    private let delay: Duration

    init(
        prompter: ReviewPrompter,
        sessionHistory: SessionHistory,
        navigator: AppNavigator,
        delay: Duration = RatingFlow.delayAfterSession
    ) {
        self.prompter = prompter
        self.sessionHistory = sessionHistory
        self.navigator = navigator
        self.delay = delay
    }

    /// A session was finished and recorded: the moment of success to ask after.
    func sessionRecorded(_ session: SessionRecord) {
        guard prompter.shouldRequestReview(after: session, sessions: sessionHistory.sessions) else { return }
        let delay = delay
        Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, navigator.isCalm else { return }
            prompter.recordRequest()
            navigator.requestReview()
        }
    }

    /// Opens a feedback email, or gives the address when there's no mail app.
    func sendFeedback() {
        Task { [weak self] in
            guard let self, await !prompter.sendFeedback() else { return }
            _ = await navigator.ask(AppDialog(
                "rating.couldntOpenMail",
                message: "rating.youCanWrite \(FeedbackEmail.supportAddress)",
                actions: [AppDialog.Action("rating.ok", id: "ok")]
            ))
        }
    }
}
