import Foundation
import Testing
@testable import Breathia

struct SupportStoreTests {
    private static let yearly = ActiveSupportSubscription(
        productID: .yearly,
        expirationDate: .now.addingTimeInterval(200 * 86_400),
        willAutoRenew: true
    )

    /// Yearly to monthly is a downgrade: yearly stays active, and monthly is what comes next.
    @Test func downgradeShowsTheNextPlan() async throws {
        let store = SupportStore(service: PreviewSupportService(subscription: Self.yearly))
        await store.load()
        let monthly = try #require(store.subscriptionOffers.first { $0.id == .monthly })

        await store.purchase(monthly)

        #expect(store.activeSubscription?.productID == .yearly)
        #expect(store.activeSubscription?.nextProductID == .monthly)
        #expect(store.isSupporter)
    }

    @Test func upgradeTakesEffectRightAway() async throws {
        let store = SupportStore(service: PreviewSupportService(subscription: ActiveSupportSubscription(
            productID: .monthly,
            expirationDate: .now.addingTimeInterval(20 * 86_400),
            willAutoRenew: true
        )))
        await store.load()
        let yearly = try #require(store.subscriptionOffers.first { $0.id == .yearly })

        await store.purchase(yearly)

        #expect(store.activeSubscription?.productID == .yearly)
        #expect(store.activeSubscription?.nextProductID == nil)
    }
}
