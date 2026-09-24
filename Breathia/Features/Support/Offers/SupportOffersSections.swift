import SwiftUI

/// The purchase options: placeholders while they load, a retry when they can't,
/// and one-time and recurring support once they're in.
struct SupportOffersSections: View {
    @Environment(SupportStore.self) private var store

    var body: some View {
        switch store.loadState {
        case .idle, .loading:
            // The same sections the offers will fill, as placeholders of the same
            // size — nothing jumps when the prices arrive, and nothing is tappable yet.
            SupportPlaceholderSection(oneTime: true, header: "support.oneTimeSupport", footer: "support.aSinglePaymentNothing")
            SupportPlaceholderSection(oneTime: false, header: "support.recurringSupport", footer: "support.recurringSupportIsOptional")

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
                        SupportPurchaseRow(offer: offer, isProminent: true)
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
                        SupportPurchaseRow(offer: offer, isProminent: false)
                    }
                } header: {
                    Text("support.recurringSupport")
                } footer: {
                    Text("support.recurringSupportIsOptional")
                }
            }
        }
    }
}
