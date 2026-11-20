// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// `ReviewPromptRepository` held in memory — for previews and tests.
final class InMemoryReviewPromptRepository: ReviewPromptRepository {
    private(set) var history: ReviewPromptHistory

    init(history: ReviewPromptHistory = ReviewPromptHistory()) {
        self.history = history
    }

    func recordRequest(version: String, date: Date) {
        history = ReviewPromptHistory(lastRequestDate: date, lastRequestVersion: version)
    }
}
#endif
