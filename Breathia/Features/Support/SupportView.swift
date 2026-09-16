import StoreKit
import SwiftUI

/// Links shown with the purchase options, as App Review requires for subscriptions.
enum SupportLinks {
    /// Apple's standard license agreement. Replace if you publish custom terms.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// The privacy policy in the app's language: published in German and English,
    /// so every other language gets English.
    static var privacyPolicy: URL {
        let language = Bundle.main.preferredLocalizations.first?.hasPrefix("de") == true ? "de" : "en"
        return URL(string: "https://www.linkandreas.de/breathia/privacy/\(language)")!
    }
}

/// Support the Developer: a quiet, optional way to pay for Breathia's development.
/// Nothing here unlocks features — the app stays fully free.
struct SupportView: View {
    @Environment(SupportStore.self) private var store
    @State private var isManagingSubscription = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                SupportHeader()
            }
            .listRowBackground(Color.clear)

            if let subscription = store.activeSubscription {
                Section {
                    ActiveSubscriptionRow(subscription: subscription)
                    Button("support.manageSubscription", action: manageSubscription)
                }
            }

            if let status = store.status {
                Section {
                    SupportStatusRow(status: status)
                }
            }

            offersSection

            Section {
                Button {
                    Task { await store.restorePurchases() }
                } label: {
                    HStack {
                        Text("support.restorePurchases")
                            #if os(macOS)
                            .foregroundStyle(.tint)
                            #endif
                        Spacer()
                        if store.isRestoring {
                            ProgressView()
                                #if os(macOS)
                                .controlSize(.small)
                                #endif
                        }
                    }
                    #if os(macOS)
                    .contentShape(.rect)
                    #endif
                }
                #if os(macOS)
                // A text action like the links below it, not a full-width push button.
                .buttonStyle(.borderless)
                #endif
                .disabled(store.isBusy)

                Link("support.termsOfUse", destination: SupportLinks.termsOfUse)
                Link("support.privacyPolicy", destination: SupportLinks.privacyPolicy)
            }
        }
        #if os(macOS)
        // Set here rather than inherited: this form is shown in a sheet, which
        // doesn't pick up the app's form style.
        .formStyle(.grouped)
        #endif
        // Loading isn't animated: the offers often arrive while the sheet is still sliding
        // up, and the placeholders have the same layout, so swapping them in place is seamless.
        .animation(.default, value: store.status)
        .animation(.default, value: store.activeSubscription)
        // Every completed purchase — one-time or a new subscription — is celebrated.
        .overlay {
            CelebrationBurst(trigger: store.celebrationCount)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: store.celebrationCount)
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        #endif
        .task { await store.load() }
    }

    /// The system sheet on iPhone and iPad; a Mac manages subscriptions in the App Store.
    private func manageSubscription() {
        #if os(iOS)
        isManagingSubscription = true
        #else
        openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
        #endif
    }

    @ViewBuilder
    private var offersSection: some View {
        switch store.loadState {
        case .idle, .loading:
            // The same sections the offers will fill, as placeholders of the same
            // size — nothing jumps when the prices arrive, and nothing is tappable yet.
            placeholderSection(oneTime: true, header: "support.oneTimeSupport", footer: "support.aSinglePaymentNothing")
            placeholderSection(oneTime: false, header: "support.recurringSupport", footer: "support.recurringSupportIsOptional")

        case .unavailable:
            Section {
                Text("support.supportOptionsCouldnt")
                    .foregroundStyle(.secondary)
                Button("common.tryAgain") {
                    Task { await store.load() }
                }
            }

        case .loaded:
            if !store.oneTimeOffers.isEmpty {
                Section {
                    ForEach(store.oneTimeOffers) { offer in
                        offerRow(offer, isProminent: true)
                    }
                } header: {
                    Text("support.oneTimeSupport")
                } footer: {
                    Text("support.aSinglePaymentNothing")
                }
            }

            if !store.subscriptionOffers.isEmpty {
                Section {
                    ForEach(store.subscriptionOffers) { offer in
                        offerRow(offer, isProminent: false)
                    }
                } header: {
                    Text("support.recurringSupport")
                } footer: {
                    Text("support.recurringSupportIsOptional")
                }
            }
        }
    }

    /// Redacted, gently pulsing rows standing in for one kind of offer while loading.
    private func placeholderSection(oneTime: Bool, header: LocalizedStringKey, footer: LocalizedStringKey) -> some View {
        Section {
            ForEach(SupportProductID.allCases.filter { $0.kind == (oneTime ? .oneTime : .subscription) }, id: \.self) { id in
                SupportOfferRow(
                    offer: Self.placeholderOffer(id),
                    isProminent: oneTime,
                    isActive: false,
                    isPurchasing: false,
                    isDisabled: true,
                    action: {}
                )
            }
            .redacted(reason: .placeholder)
            .phaseAnimator([false, true]) { rows, isBright in
                rows.opacity(isBright ? 1 : 0.5)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("support.loadingSupportOptions"))
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        }
    }

    /// A stand-in with the shape of a real offer; its text is redacted.
    private static func placeholderOffer(_ id: SupportProductID) -> SupportOffer {
        SupportOffer(
            id: id,
            displayName: "Support option",
            description: "",
            displayPrice: "0,00 €",
            billingPeriod: id.kind == .subscription ? .month : nil
        )
    }

    private func offerRow(_ offer: SupportOffer, isProminent: Bool) -> some View {
        SupportOfferRow(
            offer: offer,
            isProminent: isProminent,
            isActive: store.activeSubscription?.productID == offer.id,
            isPurchasing: store.purchasingProductID == offer.id,
            isDisabled: store.isBusy
        ) {
            Task { await store.purchase(offer) }
        }
    }
}

private struct SupportHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 52))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
            Text("support.supportBreathia")
                .font(.title2.bold())
            Text("support.breathiaIsFree")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

private struct SupportOfferRow: View {
    let offer: SupportOffer
    /// One-time support gets filled price buttons; recurring support is quieter.
    let isProminent: Bool
    let isActive: Bool
    let isPurchasing: Bool
    let isDisabled: Bool
    let action: () -> Void

    private var priceLabel: String {
        offer.billingPeriod.map { "\(offer.displayPrice), \($0.billingText)" } ?? offer.displayPrice
    }

    /// Every price button is at least this wide, so the buttons line up in a column.
    private static let priceMinimumWidth: CGFloat = 64

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: offer.id.emoji)
                .font(.title2)
                // A fixed column, so the offer names all start at the same x.
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(offer.displayName)
                    .font(.body.weight(.semibold))
                if !offer.description.isEmpty {
                    Text(offer.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                // The billing period sits with the name, so every price button stays
                // one line and the same size.
                if let period = offer.billingPeriod {
                    Text(verbatim: period.billingText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if isActive {
                Label("support.active", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                priceButton
            }
        }
    }

    @ViewBuilder
    private var priceButton: some View {
        let button = Button(action: action) {
            // Just the price: one line, never wrapped, and every button at least the
            // same width, so the buttons line up in a column.
            Text(verbatim: offer.displayPrice)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            .minimumScaleFactor(0.8)
            .monospacedDigit()
            .frame(minWidth: Self.priceMinimumWidth)
            // Keeps the button's size while the spinner shows.
            .opacity(isPurchasing ? 0 : 1)
            .overlay {
                if isPurchasing {
                    ProgressView()
                }
            }
        }
        .buttonBorderShape(.capsule)
        .disabled(isDisabled)
        .accessibilityLabel(Text(verbatim: "\(offer.displayName), \(priceLabel)"))

        if isProminent {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }
}

private struct ActiveSubscriptionRow: View {
    let subscription: ActiveSupportSubscription

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text("support.thankYouForSupporting")
                if let date = subscription.expirationDate?.formatted(date: .abbreviated, time: .omitted) {
                    Text(subscription.willAutoRenew ? "support.renewsOn \(date)" : "support.endsOn \(date)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
        }
    }
}

private struct SupportStatusRow: View {
    let status: SupportStore.Status

    var body: some View {
        switch status {
        case .thankYou:
            Label("support.thankYou", systemImage: "heart.fill")
                .foregroundStyle(.pink)
        case .pending:
            Label("support.yourPurchaseIsWaiting", systemImage: "clock")
        case .restored:
            Label("support.purchasesRestored", systemImage: "checkmark.circle")
        case .nothingToRestore:
            Label("support.thereWereNoPurchases", systemImage: "info.circle")
        case let .failed(error):
            Label(error.message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }
}

private extension SupportStoreError {
    var message: LocalizedStringKey {
        switch self {
        case .storeUnavailable:
            "support.supportOptionsCouldnt"
        case .productUnavailable, .purchaseFailed:
            "support.thePurchaseCouldnt"
        case .verificationFailed:
            "support.thePurchaseCouldntBeVerified"
        case .restoreFailed:
            "support.purchasesCouldntBeRestored"
        }
    }
}

#if DEBUG
#Preview("Support") {
    NavigationStack {
        SupportView()
            .navigationTitle("common.supportTheDeveloper")
    }
    .environment(SupportStore(service: PreviewSupportService()))
}
#endif

#if DEBUG
#Preview("Subscribed") {
    NavigationStack {
        SupportView()
    }
    .environment(SupportStore(service: PreviewSupportService(
        subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true)
    )))
}
#endif

private extension BillingPeriod {
    /// In the app's language — StoreKit's own wording follows the App Store
    /// storefront, which can differ from the language the app runs in.
    var billingText: String {
        switch self {
        case .day: String(localized: "support.billedDaily")
        case .week: String(localized: "support.billedWeekly")
        case .month: String(localized: "support.billedMonthly")
        case .year: String(localized: "support.billedYearly")
        }
    }
}
