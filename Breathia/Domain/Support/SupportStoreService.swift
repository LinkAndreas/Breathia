import Foundation

/// A support product as the App Store describes it: localized name and price.
struct SupportOffer: Identifiable, Equatable, Sendable {
    let id: SupportProductID
    let displayName: String
    let description: String
    let displayPrice: String
    /// How often a subscription renews; `nil` for one-time support. A value rather
    /// than StoreKit's text, so the app words it in its own language.
    let billingPeriod: BillingPeriod?
}

/// How often a subscription renews.
enum BillingPeriod: Equatable, Sendable {
    case day, week, month, year
}

/// The user's current recurring support, derived from verified App Store
/// entitlements — never stored by the app itself.
struct ActiveSupportSubscription: Equatable, Sendable {
    let productID: SupportProductID
    let expirationDate: Date?
    let willAutoRenew: Bool
    /// The plan it changes to at the next renewal, when the user picked another one:
    /// a downgrade (yearly to monthly) only takes effect then.
    var nextProductID: SupportProductID?
}

/// A transaction that completed outside a purchase call.
struct CompletedTransaction: Equatable, Sendable {
    let productID: SupportProductID
    /// A new purchase, such as an approved Ask to Buy — not a renewal or a refund.
    let isNewPurchase: Bool
}

enum PurchaseOutcome: Equatable, Sendable {
    /// Verified and finished.
    case purchased
    /// Waiting for approval, e.g. Ask to Buy; completes later through the
    /// transaction listener.
    case pending
    case cancelled
}

enum RestoreOutcome: Equatable, Sendable {
    /// Purchases were synced with the App Store.
    case synced
    /// The user dismissed the App Store sign-in.
    case cancelled
}

enum SupportStoreError: Error, Equatable, Sendable {
    /// The App Store couldn't be reached, or returned no products.
    case storeUnavailable
    /// The product wasn't loaded when a purchase was attempted.
    case productUnavailable
    /// The App Store's signature on the transaction didn't verify.
    case verificationFailed
    case purchaseFailed
    case restoreFailed
}

/// Everything the Support screen needs from the App Store. `StoreKitSupportService`
/// talks to StoreKit 2; `PreviewSupportService` stands in for previews and tests.
protocol SupportStoreService: AnyObject {
    /// The products available in the current storefront, in catalog order.
    func loadOffers() async throws -> [SupportOffer]
    func purchase(_ id: SupportProductID) async throws -> PurchaseOutcome
    func activeSubscription() async -> ActiveSupportSubscription?
    func restorePurchases() async throws -> RestoreOutcome
    /// Finishes transactions that complete outside a purchase call — Ask to Buy
    /// approvals, renewals, purchases on other devices — calling
    /// `onTransaction` for each. Runs until the returned task is cancelled.
    func observeTransactions(
        onTransaction: @escaping @MainActor (CompletedTransaction) async -> Void
    ) -> Task<Void, Never>
    /// Calls `onChange` whenever a subscription's status changes without a new
    /// transaction — cancelled, resumed, or switched to another plan, in the app or
    /// elsewhere. Runs until the returned task is cancelled.
    func observeSubscriptionStatus(onChange: @escaping @MainActor () async -> Void) -> Task<Void, Never>
}
