import SwiftUI

/// One tab: the section's list, with its detail page pushed on top.
struct SectionStack: View {
    let tab: AppTab
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        NavigationStack(path: Binding(
            get: { navigator.pushedDetail(in: tab).map { [$0] } ?? [] },
            set: { navigator.setPushedDetail($0.last, in: tab) }
        )) {
            SectionList(tab: tab, screens: screens)
                .navigationDestination(for: AppDetail.self) { detail in
                    SectionDetail(detail: detail, screens: screens)
                        #if os(iOS)
                        .toolbar(detail.hidesTabBar ? .hidden : .automatic, for: .tabBar)
                        #endif
                }
        }
    }
}
