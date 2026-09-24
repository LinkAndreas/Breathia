import SwiftUI

struct ActiveSubscriptionRow: View {
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
