import SwiftUI

/// The iPad sidebar: the app's sections. Selecting one swaps the split view's
/// content and detail columns.
struct AppSidebarScreen: View {
    @Binding var selection: AppTab?

    var body: some View {
        List(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                Label(LocalizedStringKey(tab.titleKey), systemImage: tab.systemImage)
                    .tag(tab)
            }
        }
        .navigationTitle("sidebar.title")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AppSidebarScreen(selection: .constant(.breathe))
    }
}
#endif
