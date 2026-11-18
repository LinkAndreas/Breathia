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

    /// Every icon's alternate icon name matches its icon in `Resources/AppIcons`.
    @Test func everyIconRoundTripsThroughItsAlternateIconName() {
        for icon in AppIconVariant.allCases {
            #expect(AppIconVariant(alternateIconName: icon.alternateIconName) == icon)
        }
    }
}
