import SwiftUI

/// Rating, feedback and sharing, together and always within reach — so nobody
/// needs to be asked, and nobody is asked twice.
struct FeedbackSettingsSection: View {
    let onSendFeedback: () -> Void

    var body: some View {
        Section {
            RateAppRow()
            SendFeedbackRow(action: onSendFeedback)
            ShareAppRow()
        } header: {
            Text("settings.feedback.header")
        } footer: {
            Text("settings.feedback.footer")
        }
    }
}

#if DEBUG
#Preview {
    Form {
        FeedbackSettingsSection(onSendFeedback: {})
    }
}
#endif
