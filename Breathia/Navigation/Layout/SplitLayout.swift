import SwiftUI

/// The wide window's layout: the sections in a sidebar, the section's list, and
/// its detail page beside it.
struct SplitLayout: View {
    let screens: AppScreens

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        let navigator = screens.navigator
        let tab = navigator.selectedTab
        let detail = navigator.columnDetail(in: tab)
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: Binding(
                get: { navigator.selectedTab },
                set: { if let tab = $0 { navigator.selectedTab = tab } }
            )) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    AppTabLabel(tab: tab)
                        .tag(tab)
                }
            }
        } content: {
            NavigationStack {
                SectionList(tab: tab, screens: screens)
            }
            .id(tab)
            .contentColumnWidth()
        } detail: {
            NavigationStack {
                SectionDetail(detail: detail, screens: screens)
            }
            .id(detail)
        }
    }
}
