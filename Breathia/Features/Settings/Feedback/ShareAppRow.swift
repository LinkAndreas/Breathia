import SwiftUI

/// Shares Breathia's App Store page with a friend.
struct ShareAppRow: View {
    var body: some View {
        ShareLink(
            item: AppStoreLinks.app,
            subject: Text(verbatim: "Breathia"),
            message: Text("settings.feedback.shareMessage")
        ) {
            SettingsLabel("settings.feedback.share", systemImage: "square.and.arrow.up.fill", color: .green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .tint(.primary)
    }
}
