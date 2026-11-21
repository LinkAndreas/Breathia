import Foundation
import Testing
@testable import Breathia

struct WhatsNewTests {
    @Test func showsOnceAfterAnUpdate() {
        #expect(WhatsNew.shouldShow(lastSeen: nil, hasCompletedOnboarding: true))
        #expect(WhatsNew.shouldShow(lastSeen: "1.5", hasCompletedOnboarding: true))
        #expect(!WhatsNew.shouldShow(lastSeen: WhatsNew.version, hasCompletedOnboarding: true))
    }

    /// Someone who saw the 1.6 features sees this release's once more.
    @Test func showsAgainForTheNextRelease() {
        #expect(WhatsNew.shouldShow(lastSeen: "1.6", hasCompletedOnboarding: true))
    }

    @MainActor
    @Test func tryingAFeatureOpensWhereItIs() {
        let navigator = AppNavigator()
        navigator.tryNewFeature(.history)
        #expect(navigator.selectedTab == .history)
        navigator.settingsPage = .health
        navigator.tryNewFeature(.feedback)
        #expect(navigator.selectedTab == .settings)
        #expect(navigator.settingsPage == nil)
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

    @MainActor
    @Test func tryingTheVersionHistoryOpensItsPage() {
        let navigator = AppNavigator()
        navigator.showWhatsNew()
        navigator.tryNewFeature(.versionHistory)
        #expect(!navigator.isShowingWhatsNew)
        #expect(navigator.selectedTab == .settings)
        #expect(navigator.settingsPage == .versionHistory)
    }

    /// Someone who saw the 1.8 features sees 1.8.3's once more.
    @Test func showsAgainForAPatchRelease() {
        #expect(WhatsNew.shouldShow(lastSeen: "1.8", hasCompletedOnboarding: true))
    }
}
