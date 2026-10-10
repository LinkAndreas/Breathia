import Foundation
import Observation

/// Purchase state for the Support the Developer screen: the available offers,
/// what's in progress, the active subscription, and the last outcome to report.
///
/// Support never unlocks a feature; this store exists to take voluntary payments
/// and say thank you — recurring supporters get the supporter app icons as a
/// thank-you. Entitlements are always read from the App Store.
@Observable
final class SupportStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        /// Offline, StoreKit unavailable, or no products configured.
        case unavailable
    }

    /// The latest outcome, shown inline on the Support screen.
    enum Status: Equatable {
        case thankYou
        case pending
        case restored
        case nothingToRestore
        case failed(SupportStoreError)
    }

    private(set) var oneTimeOffers: [SupportOffer] = []
    private(set) var subscriptionOffers: [SupportOffer] = []
    private(set) var loadState: LoadState = .idle
    private(set) var activeSubscription: ActiveSupportSubscription?
    /// Whether the subscription has been read from the App Store yet; until then, no
    /// subscription doesn't mean the user isn't a supporter.
    private(set) var hasCheckedSubscription = false
    private(set) var purchasingProductID: SupportProductID?
    /// The purchase waiting for approval, e.g. Ask to Buy.
    @ObservationIgnored private var pendingProductID: SupportProductID?
    private(set) var isRestoring = false
    private(set) var status: Status?
    /// Goes up with every completed purchase — one-time support or a new
    /// subscription, not renewals — so the screen can celebrate it.
    private(set) var celebrationCount = 0

    @ObservationIgnored private let service: SupportStoreService
    @ObservationIgnored private var transactionObserver: Task<Void, Never>?
    @ObservationIgnored private var statusObserver: Task<Void, Never>?
    @ObservationIgnored private var expiryRefresh: Task<Void, Never>?

    init(service: SupportStoreService) {
        self.service = service
    }

    var isBusy: Bool { purchasingProductID != nil || isRestoring }

    /// Whether the user supports Breathia with an active subscription, which unlocks
    /// the supporter app icons.
    var isSupporter: Bool { activeSubscription != nil }

    /// Whether the App Store confirmed there's no active subscription — never subscribed,
    /// or the subscription ended or was refunded.
    var isConfirmedNonSupporter: Bool { hasCheckedSubscription && !isSupporter }

    /// Starts listening for transactions that complete outside the purchase flow, and for
    /// subscription status changes such as a cancellation. Call once at launch so
    /// approvals and renewals are finished promptly.
    func startObservingTransactions() {
        guard transactionObserver == nil else { return }
        transactionObserver = service.observeTransactions { [weak self] transaction in
            await self?.transactionCompleted(transaction)
        }
        // Cancelling or resuming a subscription changes its status without a transaction.
        statusObserver = service.observeSubscriptionStatus { [weak self] in
            await self?.refreshSubscription()
        }
    }

    /// Reads the subscription from the App Store again, e.g. after the user managed it
    /// in the system sheet or the Settings app.
    func refreshSubscription() async {
        apply(await service.activeSubscription())
    }

    func load() async {
        guard loadState != .loading else { return }
        let wasLoaded = loadState == .loaded
        if !wasLoaded { loadState = .loading }

        // Fetch everything first and apply it in one go, so the screen changes once
        // instead of reflowing when the subscription arrives after the offers.
        let offers: [SupportOffer]?
        do {
            offers = try await service.loadOffers()
        } catch {
            offers = nil
        }
        let subscription = await service.activeSubscription()

        apply(subscription)
        if let offers {
            oneTimeOffers = offers.filter { $0.id.kind == .oneTime }
            subscriptionOffers = offers.filter { $0.id.kind == .subscription }
            loadState = offers.isEmpty ? .unavailable : .loaded
        } else if !wasLoaded {
            // Offers already on screen stay when a reload fails, e.g. briefly offline.
            loadState = .unavailable
        }
    }

    func purchase(_ offer: SupportOffer) async {
        guard !isBusy else { return }
        purchasingProductID = offer.id
        status = nil
        defer { purchasingProductID = nil }

        do {
            switch try await service.purchase(offer.id) {
            case .purchased:
                await purchaseCompleted(offer.id)
            case .pending:
                pendingProductID = offer.id
                status = .pending
            case .cancelled:
                break
            }
        } catch let error as SupportStoreError {
            status = .failed(error)
        } catch {
            status = .failed(.purchaseFailed)
        }
    }

    func restorePurchases() async {
        guard !isBusy else { return }
        isRestoring = true
        status = nil
        defer { isRestoring = false }

        do {
            // Dismissing the App Store sign-in isn't a failure: nothing to report.
            guard try await service.restorePurchases() == .synced else { return }
            apply(await service.activeSubscription())
            status = activeSubscription == nil ? .nothingToRestore : .restored
        } catch {
            status = .failed(.restoreFailed)
        }
    }

    func dismissStatus() {
        status = nil
    }

    // MARK: Private

    private func purchaseCompleted(_ id: SupportProductID) async {
        switch id.kind {
        case .oneTime:
            status = .thankYou
            celebrationCount += 1
        case .subscription:
            // The subscription section shows its own thank-you. A downgrade only takes
            // effect at the next renewal: nothing to celebrate yet.
            apply(Self.subscription(await service.activeSubscription(), afterBuying: id))
            if activeSubscription?.upcomingProductID != id {
                celebrationCount += 1
            }
        }
    }

    private func transactionCompleted(_ transaction: CompletedTransaction) async {
        // The purchase that was waiting for approval went through. Renewals, refunds and
        // other products' transactions don't celebrate or end the wait.
        if transaction.isNewPurchase, transaction.productID == pendingProductID {
            pendingProductID = nil
            if status == .pending {
                status = transaction.productID.kind == .oneTime ? .thankYou : nil
            }
            celebrationCount += 1
        }
        apply(await service.activeSubscription())
    }

    /// `subscription` with the plan just bought. The App Store can take a moment to report a
    /// change of plan, so what it says right after the purchase may not show it yet: a lower
    /// level is a downgrade, which waits for the next renewal; a higher one an upgrade, which
    /// takes effect right away.
    private static func subscription(
        _ subscription: ActiveSupportSubscription?,
        afterBuying id: SupportProductID
    ) -> ActiveSupportSubscription? {
        guard var subscription,
              subscription.productID != id,
              subscription.upcomingProductID != id,
              let bought = id.subscriptionLevel,
              let current = subscription.productID.subscriptionLevel
        else { return subscription }

        if bought > current {
            subscription.nextProductID = id
            return subscription
        }
        return ActiveSupportSubscription(productID: id, expirationDate: nil, willAutoRenew: true)
    }

    /// Shows `subscription`, and reads it again once it expires: running out makes no
    /// transaction, and StoreKit's status update for it can come late.
    private func apply(_ subscription: ActiveSupportSubscription?) {
        activeSubscription = subscription
        hasCheckedSubscription = true

        expiryRefresh?.cancel()
        expiryRefresh = nil
        guard let expirationDate = subscription?.expirationDate else { return }
        expiryRefresh = Task { [weak self] in
            // A moment past the date, so the App Store no longer counts it as active.
            let delay = max(expirationDate.timeIntervalSinceNow, 0) + 1
            guard (try? await Task.sleep(for: .seconds(delay))) != nil else { return }
            await self?.refreshSubscription()
        }
    }
}
