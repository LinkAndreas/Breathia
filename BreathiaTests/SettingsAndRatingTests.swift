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
    @Test func asksOnceAfterEnoughSessions() {
        let policy = ReviewPromptPolicy()
        #expect(!policy.shouldAsk(completedSessions: 2, hasAsked: false))
        #expect(policy.shouldAsk(completedSessions: 3, hasAsked: false))
        #expect(!policy.shouldAsk(completedSessions: 10, hasAsked: true))
    }

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
