import Foundation

/// When to show the system's App Store rating dialog, following Apple's guidance:
/// only after the user has clearly engaged with the app, right after a moment of
/// success, never during a task, and rarely.
///
/// The dialog is shown as is — no question beforehand that sends only happy users
/// to the App Store. Feedback and a link to rate are always in Settings instead.
struct ReviewPromptPolicy {
    /// Recorded sessions before the first request, so the user knows the app.
    static let minimumSessions = 3
    /// Days with a session, so one long first evening isn't taken for a habit.
    static let minimumDaysOfUse = 2
    /// Share of its planned length a session must have lasted: finishing what
    /// they set out to do is the moment of success to ask after.
    static let completedShare = 0.8
    /// Time between requests. The system shows the dialog at most three times
    /// a year anyway; asking less often than it allows feels less pushy.
    static let minimumDaysBetweenRequests = 120

    /// Whether to request the dialog after `session` was recorded.
    ///
    /// - Parameters:
    ///   - session: The session just finished and recorded.
    ///   - sessions: Every recorded session, including `session`.
    ///   - appVersion: The running version; a version is asked about once.
    ///   - history: When and in which version the dialog was last requested.
    func shouldRequestReview(
        after session: SessionRecord,
        sessions: [SessionRecord],
        appVersion: String,
        history: ReviewPromptHistory,
        now: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard sessions.count >= Self.minimumSessions else { return false }

        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        guard days.count >= Self.minimumDaysOfUse else { return false }

        let planned = TimeInterval(session.technique.recommendedDuration)
        guard planned > 0, session.duration >= planned * Self.completedShare else { return false }

        guard history.lastRequestVersion != appVersion else { return false }
        if let last = history.lastRequestDate {
            let days = calendar.dateComponents([.day], from: last, to: now).day ?? 0
            guard days >= Self.minimumDaysBetweenRequests else { return false }
        }
        return true
    }
}

/// When the rating dialog was last requested.
struct ReviewPromptHistory: Equatable {
    var lastRequestDate: Date?
    var lastRequestVersion: String?
}
