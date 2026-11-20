import SwiftUI

/// A section's list: the root of its stack in the tab bar, the content column in
/// the split view.
struct SectionList: View {
    let tab: AppTab
    let screens: AppScreens

    var body: some View {
        switch tab {
        case .breathe: BreatheList(screens: screens)
        case .history: HistoryList(screens: screens)
        case .settings: SettingsList(screens: screens)
        }
    }
}
