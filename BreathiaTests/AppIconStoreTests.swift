import Foundation
import Testing
@testable import Breathia

struct AppIconStoreTests {
    private struct Refused: Error {}

    @Test func startsWithTheAppsIcon() {
        #expect(AppIconStore(alternateIconName: "AppIcon-Ember") { _ in }.current == .ember)
        #expect(AppIconStore(alternateIconName: nil) { _ in }.current == .classic)
        #expect(AppIconStore(alternateIconName: "AppIcon-Removed") { _ in }.current == .classic)
    }

    @Test func selectingAnIconChangesTheAppsIcon() async throws {
        var requestedNames: [String?] = []
        let store = AppIconStore(alternateIconName: nil) { requestedNames.append($0) }

        try await store.select(.noir)
        try await store.select(.classic)

        #expect(requestedNames == ["AppIcon-Noir", nil])
        #expect(store.current == .classic)
    }

    @Test func selectingTheCurrentIconDoesntAskTheSystemAgain() async throws {
        var requestCount = 0
        let store = AppIconStore(alternateIconName: "AppIcon-Lagoon") { _ in requestCount += 1 }

        try await store.select(.lagoon)

        #expect(requestCount == 0)
    }

    @Test func goesBackWhenTheSystemRefusesTheIcon() async {
        let store = AppIconStore(alternateIconName: "AppIcon-Blush") { _ in throw Refused() }

        await #expect(throws: Refused.self) {
            try await store.select(.glacier)
        }
        #expect(store.current == .blush)
    }

    @Test func endingSupportGoesBackToTheDefaultIcon() async {
        var requestedNames: [String?] = []
        let store = AppIconStore(alternateIconName: "AppIcon-Ember") { requestedNames.append($0) }

        await store.supportEnded()
        await store.supportEnded()

        #expect(store.current == .classic)
        #expect(requestedNames == [nil])
    }

    @Test func resumingSupportBringsBackTheIcon() async {
        var requestedNames: [String?] = []
        let store = AppIconStore(alternateIconName: "AppIcon-Ember") { requestedNames.append($0) }

        await store.supportEnded()
        await store.supportResumed()
        await store.supportResumed()

        #expect(store.current == .ember)
        #expect(requestedNames == [nil, "AppIcon-Ember"])
    }

    @Test func resumingSupportKeepsAnIconPickedSince() async throws {
        let store = AppIconStore(alternateIconName: "AppIcon-Ember") { _ in }

        await store.supportEnded()
        try await store.select(.noir)
        await store.supportResumed()

        #expect(store.current == .noir)
    }

    @Test func resumingSupportWithoutALapsedIconChangesNothing() async {
        var requestCount = 0
        let store = AppIconStore(alternateIconName: nil) { _ in requestCount += 1 }

        await store.supportResumed()

        #expect(store.current == .classic)
        #expect(requestCount == 0)
    }

    @Test func endingSupportIsTriedAgainAfterTheSystemRefused() async {
        var isRefusing = true
        let store = AppIconStore(alternateIconName: "AppIcon-Lagoon") { _ in
            if isRefusing { throw Refused() }
        }

        await store.supportEnded()
        #expect(store.current == .lagoon)

        isRefusing = false
        await store.supportEnded()
        #expect(store.current == .classic)

        await store.supportResumed()
        #expect(store.current == .lagoon)
    }

    @Test func remembersTheLapsedIconAcrossLaunches() async throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        await AppIconStore(alternateIconName: "AppIcon-Blush", defaults: defaults) { _ in }.supportEnded()
        let relaunched = AppIconStore(alternateIconName: nil, defaults: defaults) { _ in }
        await relaunched.supportResumed()

        #expect(relaunched.current == .blush)
    }

    /// Every icon's alternate icon name matches its icon in `Resources/AppIcons`.
    @Test func everyIconRoundTripsThroughItsAlternateIconName() {
        for icon in SupporterIcon.allCases {
            #expect(SupporterIcon(alternateIconName: icon.alternateIconName) == icon)
        }
    }
}
