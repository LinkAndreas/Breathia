import Foundation
import OSLog
import StoreKit
#if os(macOS)
import AppKit
#endif

/// `SupportStoreService` backed by StoreKit 2. The only place in the app that
/// imports StoreKit's purchasing API.
final class StoreKitSupportService: SupportStoreService {
    private var products: [SupportProductID: Product] = [:]
    private let logger = Logger(subsystem: "Breathia", category: "Support")

    func loadOffers() async throws -> [SupportOffer] {
        let storeProducts: [Product]
        do {
            storeProducts = try await Product.products(for: SupportProductID.allCases.map(\.rawValue))
        } catch {
            throw SupportStoreError.storeUnavailable
        }

        var offers: [SupportOffer] = []
        for product in storeProducts {
            guard let id = SupportProductID(rawValue: product.id) else { continue }
            products[id] = product
            offers.append(SupportOffer(
                id: id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice,
                billingPeriod: product.subscription.map { BillingPeriod($0.subscriptionPeriod.unit) }
            ))
        }

        // Keep the catalog's order rather than the App Store's.
        let order = SupportProductID.allCases
        return offers.sorted { order.firstIndex(of: $0.id)! < order.firstIndex(of: $1.id)! }
    }

    func purchase(_ id: SupportProductID) async throws -> PurchaseOutcome {
        guard let product = products[id] else { throw SupportStoreError.productUnavailable }

        let result: Product.PurchaseResult
        do {
            result = try await purchase(product)
        } catch {
            logger.error("Buying \(id.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            throw SupportStoreError.purchaseFailed
        }

        switch result {
        case let .success(verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func activeSubscription() async -> ActiveSupportSubscription? {
        // The subscription's status is the App Store's own answer: whether it's active, whether
        // it renews, and into which plan. Without one — offline before the products ever
        // loaded — the transactions on the device stand in.
        let statuses = await subscriptionStatuses() ?? []
        if let subscription = statuses.lazy.compactMap(Self.activeSubscription(from:)).first {
            return subscription
        }
        // A status can lag behind a purchase; the transaction is already there.
        guard let transaction = await activeSubscriptionTransaction(),
              let id = SupportProductID(rawValue: transaction.productID)
        else { return nil }
        let renewal = statuses.lazy
            .compactMap { status -> Product.SubscriptionInfo.RenewalInfo? in
                guard case let .verified(info) = status.renewalInfo, info.originalTransactionID == transaction.originalID
                else { return nil }
                return info
            }
            .first
        return Self.subscription(id, transaction: transaction, renewal: renewal)
    }

    func restorePurchases() async throws -> RestoreOutcome {
        do {
            try await AppStore.sync()
            return .synced
        } catch StoreKitError.userCancelled {
            return .cancelled
        } catch {
            throw SupportStoreError.restoreFailed
        }
    }

    func observeTransactions(
        onTransaction: @escaping @MainActor (CompletedTransaction) async -> Void
    ) -> Task<Void, Never> {
        Task {
            // Transactions left unfinished last time, e.g. the app quit mid-purchase.
            for await result in Transaction.unfinished {
                _ = await finishIfVerified(result)
            }
            for await result in Transaction.updates {
                if let completed = await finishIfVerified(result) {
                    await onTransaction(completed)
                }
            }
        }
    }

    func observeSubscriptionStatus(onChange: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        Task {
            for await _ in Product.SubscriptionInfo.Status.updates {
                await onChange()
            }
        }
    }

    // MARK: Private

    /// Buys `product`. A Mac shows the App Store's confirmation over a window, which it has to be
    /// given; on iPhone and iPad StoreKit finds the scene itself.
    private func purchase(_ product: Product) async throws -> Product.PurchaseResult {
        #if os(macOS)
        if let window = await MainActor.run(body: { NSApp.keyWindow ?? NSApp.mainWindow }) {
            return try await product.purchase(confirmIn: window)
        }
        #endif
        return try await product.purchase()
    }

    /// The transaction of the subscription that's active now, if any. `currentEntitlements` only
    /// contains subscriptions that are still active; right after an upgrade it can still list
    /// the plan that was upgraded from, which no longer counts.
    private func activeSubscriptionTransaction() async -> Transaction? {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result, Self.isActiveSubscription(transaction) else { continue }
            return transaction
        }
        // `currentEntitlements` can leave out a subscription that was just bought — with StoreKit
        // testing it can stay empty — while each plan's latest transaction has it. Higher tier first.
        for id in [SupportProductID.yearly, .monthly] {
            guard case let .verified(transaction)? = await Transaction.latest(for: id.rawValue),
                  Self.isActiveSubscription(transaction)
            else { continue }
            return transaction
        }
        return nil
    }

    /// The statuses of Breathia's subscription group, or `nil` when the App Store can't say.
    private func subscriptionStatuses() async -> [Product.SubscriptionInfo.Status]? {
        let product: Product?
        if let cached = products.values.first(where: { $0.subscription != nil }) {
            product = cached
        } else {
            product = try? await Product.products(for: [SupportProductID.monthly.rawValue]).first
        }
        return try? await product?.subscription?.status
    }

    /// The subscription a status describes, if it counts as active.
    private static func activeSubscription(from status: Product.SubscriptionInfo.Status) -> ActiveSupportSubscription? {
        guard status.state == .subscribed || status.state == .inGracePeriod,
              case let .verified(transaction) = status.transaction,
              isActiveSubscription(transaction),
              let id = SupportProductID(rawValue: transaction.productID)
        else { return nil }

        let renewal: Product.SubscriptionInfo.RenewalInfo? = if case let .verified(info) = status.renewalInfo { info } else { nil }
        return subscription(id, transaction: transaction, renewal: renewal)
    }

    private static func subscription(
        _ id: SupportProductID,
        transaction: Transaction,
        renewal: Product.SubscriptionInfo.RenewalInfo?
    ) -> ActiveSupportSubscription {
        ActiveSupportSubscription(
            productID: id,
            expirationDate: transaction.expirationDate,
            willAutoRenew: renewal?.willAutoRenew ?? true,
            // A downgrade only takes effect at the next renewal.
            nextProductID: renewal?.autoRenewPreference
                .flatMap(SupportProductID.init(rawValue:))
                .flatMap { $0 == id ? nil : $0 }
        )
    }

    private static func isActiveSubscription(_ transaction: Transaction) -> Bool {
        transaction.productType == .autoRenewable
            && transaction.revocationDate == nil
            && !transaction.isUpgraded
            && SupportProductID(rawValue: transaction.productID) != nil
            && (transaction.expirationDate.map { $0 > .now } ?? true)
    }

    /// Finishes a verified transaction and describes it. Unverified transactions are
    /// left unfinished and ignored.
    private func finishIfVerified(_ result: VerificationResult<Transaction>) async -> CompletedTransaction? {
        guard case let .verified(transaction) = result else { return nil }
        await transaction.finish()
        guard let id = SupportProductID(rawValue: transaction.productID) else { return nil }
        return CompletedTransaction(
            productID: id,
            isNewPurchase: transaction.revocationDate == nil && transaction.reason == .purchase
        )
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .verified(value): value
        case .unverified: throw SupportStoreError.verificationFailed
        }
    }
}

private extension BillingPeriod {
    init(_ unit: Product.SubscriptionPeriod.Unit) {
        self = switch unit {
        case .day: .day
        case .week: .week
        case .year: .year
        default: .month
        }
    }
}
