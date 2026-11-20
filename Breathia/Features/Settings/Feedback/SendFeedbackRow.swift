import SwiftUI

/// Writes to the developer: an email with the app and device details filled in.
struct SendFeedbackRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsLabel("settings.feedback.send", systemImage: "envelope.fill", tone: .feedback)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .tint(.primary)
        .accessibilityHint(Text("settings.feedback.sendHint"))
    }
}
