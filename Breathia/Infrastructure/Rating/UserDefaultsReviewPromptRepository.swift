import Foundation

/// `ReviewPromptRepository` backed by `UserDefaults`.
struct UserDefaultsReviewPromptRepository: ReviewPromptRepository {
    private static let lastRequestDateKey = "com.breathia.reviewPrompt.lastRequestDate"
    private static let lastRequestVersionKey = "com.breathia.reviewPrompt.lastRequestVersion"
    /// Set by versions up to 1.7, which asked once whether the user enjoyed the app.
    private static let legacyHasAskedKey = "com.breathia.reviewPrompt.hasAsked"

    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
    }

    var history: ReviewPromptHistory {
        if defaults.object(forKey: Self.lastRequestDateKey) == nil, defaults.bool(forKey: Self.legacyHasAskedKey) {
            // Asked by an earlier version on a day nobody kept: count it as today,
            // so they aren't asked again soon.
            recordRequest(version: "legacy", date: now())
        }
        return ReviewPromptHistory(
            lastRequestDate: defaults.object(forKey: Self.lastRequestDateKey) as? Date,
            lastRequestVersion: defaults.string(forKey: Self.lastRequestVersionKey)
        )
    }

    func recordRequest(version: String, date: Date) {
        defaults.set(date, forKey: Self.lastRequestDateKey)
        defaults.set(version, forKey: Self.lastRequestVersionKey)
    }
}
