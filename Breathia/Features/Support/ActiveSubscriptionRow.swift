import SwiftUI

struct ActiveSubscriptionRow: View {
    let subscription: ActiveSupportSubscription
    /// The name of the plan it changes to at the next renewal, if the user picked another one.
    var nextPlanName: String?

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text("support.thankYouForSupporting")
                if let date = subscription.expirationDate?.formatted(date: .abbreviated, time: .omitted) {
                    Group {
                        if !subscription.willAutoRenew {
                            Text("support.endsOn \(date)")
                        } else if let nextPlanName {
                            Text("support.changesTo \(nextPlanName) \(date)")
                        } else {
                            Text("support.renewsOn \(date)")
                        }
                    }
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

#if DEBUG
#Preview {
    List {
        ActiveSubscriptionRow(subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true))
        ActiveSubscriptionRow(
            subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true, nextProductID: .monthly),
            nextPlanName: "Monthly Support"
        )
    }
}
#endif
