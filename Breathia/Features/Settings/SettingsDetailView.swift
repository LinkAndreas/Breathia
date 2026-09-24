import SwiftUI

/// One settings page — the iPad detail column, or a page pushed on iPhone.
struct SettingsDetailView: View {
    let page: SettingsPage

    var body: some View {
        SettingsPageContent(page: page)
            .navigationTitle(page.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsDetailView(page: .breathing)
    }
    .environment(PreviewStores.settingsStore())
}
#endif
