import SwiftUI

/// A section's title and symbol, in the tab bar and the sidebar.
struct AppTabLabel: View {
    let tab: AppTab

    var body: some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.systemImage)
        }
    }
}
