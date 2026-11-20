import SwiftUI

/// A settings page as a row that opens it, with a chevron like a navigation link.
struct SettingsPageRow: View {
    let page: SettingsPage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                SettingsLabel(verbatim: page.title, systemImage: page.systemImage, tone: page.tone)
                Spacer()
                DisclosureChevron()
            }
        }
        .tint(.primary)
    }
}

#if DEBUG
#Preview {
    Form {
        SettingsPageRow(page: .privacy) {}
        SettingsPageRow(page: .aboutSensor) {}
    }
}
#endif
