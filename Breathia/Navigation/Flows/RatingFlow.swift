import Foundation
import NavigationKit

/// The "Do you enjoy Breathia?" conversation after a session: asks once,
/// when `ReviewPrompter` says it's time, then requests an App Store rating or opens
/// a feedback email. Its alerts are presented over the whole app by `AppNavigator`.
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
            self?.ask()
        }
    }

    private func ask() {
        prompter.markAsked()
        navigator.present(alert: AlertSpec(
            title: String(localized: "rating.doYouEnjoyBreathia"),
            message: String(localized: "rating.yourAnswerHelpsUs"),
            buttons: [
                AlertSpec.Button(String(localized: "rating.notReally")) { [weak self] in
                    Task { await self?.sendFeedback() }
                },
                AlertSpec.Button(String(localized: "rating.yes")) { [weak self] in
                    self?.prompter.userEnjoysApp()
                },
            ]
        ))
    }

    private func sendFeedback() async {
        guard await !prompter.userDoesNotEnjoyApp() else { return }
        // No mail app is set up; give the address instead.
        navigator.present(alert: AlertSpec(
            title: String(localized: "rating.couldntOpenMail"),
            message: String(localized: "rating.youCanWrite \(FeedbackEmail.supportAddress)"),
            buttons: [AlertSpec.Button(String(localized: "rating.ok"))]
        ))
    }
}
