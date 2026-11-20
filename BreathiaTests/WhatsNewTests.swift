import Foundation
import Testing
@testable import Breathia

struct WhatsNewTests {
    @Test func showsOnceAfterAnUpdate() {
        #expect(WhatsNew.shouldShow(lastSeen: nil, hasCompletedOnboarding: true))
        #expect(WhatsNew.shouldShow(lastSeen: "1.5", hasCompletedOnboarding: true))
        #expect(!WhatsNew.shouldShow(lastSeen: WhatsNew.version, hasCompletedOnboarding: true))
    }

    @Test func newUsersGetOnboardingInstead() {
        #expect(!WhatsNew.shouldShow(lastSeen: nil, hasCompletedOnboarding: false))
    }

    @Test func theSeenReleaseIsKept() throws {
        var settings = AppSettings()
        settings.lastSeenWhatsNew = "1.6"
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded.lastSeenWhatsNew == "1.6")

        let older = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"hasCompletedOnboarding": true}"#.utf8))
        #expect(older.lastSeenWhatsNew == nil)
    }

    @MainActor
    @Test func tryingTheSoundsOpensTheirSettings() {
        let navigator = AppNavigator()
        navigator.showWhatsNew()
        navigator.tryNewFeature(.soundSettings)
        #expect(!navigator.isShowingWhatsNew)
        #expect(navigator.selectedTab == .settings)
        #expect(navigator.settingsPage == .sound)
    }
}
