import StoreKit
import SwiftUI

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

            SupportOffersSections()

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
