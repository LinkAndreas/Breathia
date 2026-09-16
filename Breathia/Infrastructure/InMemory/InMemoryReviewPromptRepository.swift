// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// `ReviewPromptRepository` held in memory — for previews and tests.
final class InMemoryReviewPromptRepository: ReviewPromptRepository {
    private(set) var hasAsked: Bool

    init(hasAsked: Bool = false) {
        self.hasAsked = hasAsked
    }

    func markAsked() {
        hasAsked = true
    }
}
#endif
