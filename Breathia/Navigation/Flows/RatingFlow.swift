import Foundation

/// The "Do you enjoy Breathia?" conversation after a session: asks once,
/// when `ReviewPrompter` says it's time, then requests an App Store rating or opens
/// a feedback email. Its dialogs are presented over the whole app by `AppNavigator`.
final class RatingFlow {
    private let prompter: ReviewPrompter
    private let sessionHistory: SessionHistory
    private let navigator: AppNavigator

    init(prompter: ReviewPrompter, sessionHistory: SessionHistory, navigator: AppNavigator) {
        self.prompter = prompter
        self.sessionHistory = sessionHistory
        self.navigator = navigator
    }

    /// After a recorded session, asks once whether the user enjoys the app — when
    /// enough sessions are completed and the question hasn't been asked before.
    func askIfAppropriate() {
        guard prompter.shouldAsk(completedSessions: sessionHistory.sessions.count) else { return }
        Task { [weak self] in
            // Let the session screen finish closing, so the question arrives on a
            // settled screen rather than mid-transition.
            try? await Task.sleep(for: .seconds(0.8))
            await self?.ask()
        }
    }

    private func ask() async {
        prompter.markAsked()
        let notReally = "notReally"
        let choice = await navigator.ask(AppDialog(
            "rating.doYouEnjoyBreathia",
            message: "rating.yourAnswerHelpsUs",
            actions: [
                AppDialog.Action("rating.notReally", id: notReally),
                AppDialog.Action("rating.yes", id: "yes"),
            ]
        ))
        switch choice {
        case notReally?: await sendFeedback()
        case .some: prompter.userEnjoysApp()
        case nil: break
        }
    }

    private func sendFeedback() async {
        guard await !prompter.userDoesNotEnjoyApp() else { return }
        // No mail app is set up; give the address instead, once the first
        // question has finished closing.
        try? await Task.sleep(for: .seconds(0.5))
        _ = await navigator.ask(AppDialog(
            "rating.couldntOpenMail",
            message: "rating.youCanWrite \(FeedbackEmail.supportAddress)",
            actions: [AppDialog.Action("rating.ok", id: "ok")]
        ))
    }
}
