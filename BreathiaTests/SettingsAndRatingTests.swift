import Foundation
import Testing
@testable import Breathia

struct AppSettingsTests {
    /// Settings saved by an older version keep their values when a setting is added.
    @Test func decodesMissingKeysAsDefaults() throws {
        let json = Data(#"{"soundEnabled": false, "hrvMetric": "sdnn"}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: json)
        #expect(!settings.soundEnabled)
        #expect(settings.hrvMetric == .sdnn)
        #expect(settings.hapticsEnabled)
        #expect(!settings.savesMindfulMinutes)
    }

    @Test func roundTrips() throws {
        var settings = AppSettings()
        settings.appearance = .dark
        settings.feedbackSensitivity = .high
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }

    @Test func storeWritesChangesThrough() {
        let repository = InMemorySettingsRepository()
        let store = SettingsStore(repository: repository)
        store.completeOnboarding()
        #expect(repository.loadSettings().hasCompletedOnboarding)
    }
}

struct RatingTests {
    @Test func feedbackEmailCarriesTheDetails() throws {
        let email = FeedbackEmail(
            subject: "Feedback & ideas",
            prompt: "Tell us more",
            metadata: AppMetadata(
                appName: "Breathia", appVersion: "1.0", buildNumber: "7", deviceModel: "iPhone17,1",
                systemName: "iOS", systemVersion: "27.0", localeIdentifier: "de_DE"
            )
        )
        let url = try #require(email.mailtoURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.scheme == "mailto")
        #expect(components.path == FeedbackEmail.supportAddress)
        #expect(components.queryItems?.first { $0.name == "subject" }?.value == "Feedback & ideas")
        #expect(email.body.contains("Breathia 1.0 (7)"))
        #expect(email.body.contains("iPhone17,1"))
    }
}

/// The App Store rating dialog comes only when Apple's guidance allows it: after
/// real engagement, right after a finished session, rarely.
struct ReviewPromptPolicyTests {
    private let policy = ReviewPromptPolicy()
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// A session on `day` days before now, lasting `share` of its planned length.
    private func session(daysAgo day: Int, share: Double = 1) -> SessionRecord {
        let technique = TechniqueCatalog.technique(withID: "box")
        return SessionRecord(
            id: UUID(),
            date: now.addingTimeInterval(-Double(day) * 86_400),
            techniqueID: technique.id,
            duration: Double(technique.recommendedDuration) * share,
            heartRate: nil, hrv: nil, heartRateTrace: [], source: .iPhone
        )
    }

    private func shouldRequest(
        _ sessions: [SessionRecord],
        history: ReviewPromptHistory = ReviewPromptHistory(),
        version: String = "1.7.0"
    ) -> Bool {
        policy.shouldRequestReview(
            after: sessions[0], sessions: sessions, appVersion: version,
            history: history, now: now, calendar: calendar
        )
    }

    @Test func requestsAfterEngagementAndAFinishedSession() {
        #expect(shouldRequest([session(daysAgo: 0), session(daysAgo: 1), session(daysAgo: 3)]))
    }

    @Test func waitsForEnoughSessions() {
        #expect(!shouldRequest([session(daysAgo: 0), session(daysAgo: 1)]))
    }

    @Test func waitsForMoreThanOneDayOfUse() {
        #expect(!shouldRequest([session(daysAgo: 0), session(daysAgo: 0), session(daysAgo: 0)]))
    }

    @Test func neverAfterASessionEndedEarly() {
        #expect(!shouldRequest([session(daysAgo: 0, share: 0.5), session(daysAgo: 1), session(daysAgo: 3)]))
    }

    @Test func asksOncePerVersionAndRarely() {
        let sessions = [session(daysAgo: 0), session(daysAgo: 1), session(daysAgo: 3)]
        let recent = ReviewPromptHistory(lastRequestDate: now.addingTimeInterval(-30 * 86_400), lastRequestVersion: "1.6.0")
        #expect(!shouldRequest(sessions, history: recent))

        let sameVersion = ReviewPromptHistory(lastRequestDate: now.addingTimeInterval(-200 * 86_400), lastRequestVersion: "1.7.0")
        #expect(!shouldRequest(sessions, history: sameVersion))

        let longAgo = ReviewPromptHistory(lastRequestDate: now.addingTimeInterval(-200 * 86_400), lastRequestVersion: "1.6.0")
        #expect(shouldRequest(sessions, history: longAgo))
    }

    @Test func someoneAskedByAnEarlierVersionIsNotAskedSoon() throws {
        let defaults = try #require(UserDefaults(suiteName: "ReviewPromptPolicyTests.\(UUID())"))
        defaults.set(true, forKey: "com.breathia.reviewPrompt.hasAsked")
        let repository = UserDefaultsReviewPromptRepository(defaults: defaults, now: { self.now })

        let history = repository.history
        #expect(history.lastRequestDate == now)
        let sessions = [session(daysAgo: 0), session(daysAgo: 1), session(daysAgo: 3)]
        #expect(!shouldRequest(sessions, history: history))
    }
}

@MainActor
struct RatingFlowTests {
    private struct Mailer: FeedbackMailing {
        func compose(_ email: FeedbackEmail) async -> Bool { true }
    }

    private struct Metadata: AppMetadataProviding {
        var metadata: AppMetadata {
            AppMetadata(appName: "Breathia", appVersion: "1.7.0", buildNumber: "1", deviceModel: "x",
                        systemName: "iOS", systemVersion: "27", localeIdentifier: "en")
        }
    }

    private func sessions() -> [SessionRecord] {
        let technique = TechniqueCatalog.technique(withID: "box")
        return (0..<3).map { day in
            SessionRecord(
                id: UUID(), date: .now.addingTimeInterval(-Double(day) * 86_400), techniqueID: technique.id,
                duration: Double(technique.recommendedDuration), heartRate: nil, hrv: nil,
                heartRateTrace: [], source: .iPhone
            )
        }
    }

    private func waitPastTheDelay() async throws {
        try await Task.sleep(for: RatingFlow.delayAfterSession + .milliseconds(700))
    }

    @Test func requestsTheSystemDialogAfterAFinishedSession() async throws {
        let sessions = sessions()
        let navigator = AppNavigator()
        let repository = InMemoryReviewPromptRepository()
        let flow = RatingFlow(
            prompter: ReviewPrompter(repository: repository, mailer: Mailer(), metadataProvider: Metadata()),
            sessionHistory: SessionHistory(repository: InMemorySessionRepository(sessions: sessions)),
            navigator: navigator
        )
        flow.sessionRecorded(sessions[0])
        try await waitPastTheDelay()

        #expect(navigator.reviewRequest == 1)
        #expect(repository.history.lastRequestVersion == "1.7.0")

        // Not again in this version.
        flow.sessionRecorded(sessions[0])
        try await waitPastTheDelay()
        #expect(navigator.reviewRequest == 1)
    }

    @Test func neverInterruptsANewSession() async throws {
        let sessions = sessions()
        let navigator = AppNavigator()
        let repository = InMemoryReviewPromptRepository()
        let flow = RatingFlow(
            prompter: ReviewPrompter(repository: repository, mailer: Mailer(), metadataProvider: Metadata()),
            sessionHistory: SessionHistory(repository: InMemorySessionRepository(sessions: sessions)),
            navigator: navigator
        )
        flow.sessionRecorded(sessions[0])
        // The user starts the next session right away.
        navigator.startSession(with: TechniqueCatalog.technique(withID: "box"))
        try await waitPastTheDelay()

        #expect(navigator.reviewRequest == 0)
        // Not recorded either, so a later moment can still ask.
        #expect(repository.history.lastRequestDate == nil)
    }
}
