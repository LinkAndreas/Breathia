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

    /// Cancelling happens in the system's subscription management, with no transaction:
    /// refreshing picks it up, and the subscription shows when it ends.
    @Test func refreshingPicksUpACancellation() async {
        let service = PreviewSupportService(subscription: Self.yearly)
        let store = SupportStore(service: service)
        await store.load()
        #expect(store.activeSubscription?.willAutoRenew == true)

        service.subscription = ActiveSupportSubscription(
            productID: .yearly,
            expirationDate: Self.yearly.expirationDate,
            willAutoRenew: false
        )
        await store.refreshSubscription()

        #expect(store.activeSubscription?.willAutoRenew == false)
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

    /// While Ask to Buy waits, a renewal or another product's transaction mustn't look like the approval.
    @Test func onlyTheApprovedPurchaseEndsTheWait() async throws {
        let service = PreviewSupportService()
        service.purchaseOutcome = .pending
        let store = SupportStore(service: service)
        store.startObservingTransactions()
        await store.load()
        let generous = try #require(store.oneTimeOffers.first { $0.id == .generous })

        await store.purchase(generous)
        #expect(store.status == .pending)

        let complete = try #require(service.completeTransaction)
        await complete(CompletedTransaction(productID: .yearly, isNewPurchase: false))
        await complete(CompletedTransaction(productID: .small, isNewPurchase: true))
        #expect(store.status == .pending)
        #expect(store.celebrationCount == 0)

        await complete(CompletedTransaction(productID: .generous, isNewPurchase: true))
        #expect(store.status == .thankYou)
        #expect(store.celebrationCount == 1)
    }

    @Test func cancellingTheRestoreSignInReportsNothing() async {
        let service = PreviewSupportService()
        service.restoreOutcome = .cancelled
        let store = SupportStore(service: service)

        await store.restorePurchases()

        #expect(store.status == nil)
    }

    @Test func aFailedReloadKeepsTheOffers() async {
        let service = PreviewSupportService()
        let store = SupportStore(service: service)
        await store.load()

        service.failsToLoad = true
        await store.load()

        #expect(store.loadState == .loaded)
        #expect(!store.oneTimeOffers.isEmpty)
    }
}
