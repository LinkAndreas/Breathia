import SwiftUI

/// Opens Breathia's App Store page on writing a review — whenever the user
/// chooses to, as Apple recommends alongside the system's rating dialog.
struct RateAppRow: View {
    var body: some View {
        Link(destination: AppStoreLinks.writeReview) {
            HStack {
                SettingsLabel("settings.feedback.rate", systemImage: "star.fill", color: .yellow)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .tint(.primary)
        .accessibilityHint(Text("settings.feedback.rateHint"))
    }
}
