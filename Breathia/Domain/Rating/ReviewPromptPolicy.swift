import Foundation

/// When to ask whether the user enjoys the app: once, after enough completed
/// sessions for them to have formed an opinion.
struct ReviewPromptPolicy {
    static let completedSessionsBeforeAsking = 3

    func shouldAsk(completedSessions: Int, hasAsked: Bool) -> Bool {
        !hasAsked && completedSessions >= Self.completedSessionsBeforeAsking
    }
}
