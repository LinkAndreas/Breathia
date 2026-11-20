import SwiftUI

/// The narrow window's layout: a tab per section.
struct TabLayout: View {
    let screens: AppScreens

    var body: some View {
        @Bindable var navigator = screens.navigator
        TabView(selection: $navigator.selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(value: tab) {
                    SectionStack(tab: tab, screens: screens)
                } label: {
                    AppTabLabel(tab: tab)
                }
            }
        }
        #if os(iOS)
        .tabBarMinimizeBehavior(.never)
        #endif
    }
}
