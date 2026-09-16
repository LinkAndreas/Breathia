import Foundation

/// `ReviewPromptRepository` backed by `UserDefaults`.
struct UserDefaultsReviewPromptRepository: ReviewPromptRepository {
    private static let hasAskedKey = "com.breathia.reviewPrompt.hasAsked"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasAsked: Bool {
        defaults.bool(forKey: Self.hasAskedKey)
    }

    func markAsked() {
        defaults.set(true, forKey: Self.hasAskedKey)
    }
}
