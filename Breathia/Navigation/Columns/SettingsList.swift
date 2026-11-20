import SwiftUI

/// Settings' first column: every setting in one form in the tab bar; the
/// categories, like the Settings app, in the split view.
struct SettingsList: View {
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        if navigator.usesSplitLayout {
            SettingsCategoryList(
                selection: Binding(
                    get: { navigator.selectedSettingsPage },
                    set: { page in
                        if let page { navigator.settingsPage = page }
                    }
                ),
                onShowOnboarding: { navigator.showOnboarding() },
                onShowWhatsNew: { navigator.showWhatsNew() },
                onSendFeedback: { screens.ratingFlow.sendFeedback() }
            )
            .environment(screens.mindfulMinutes)
        } else {
            SettingsView(
                onShowSensor: { navigator.showSensor() },
                onOpenPage: { navigator.settingsPage = $0 },
                onShowOnboarding: { navigator.showOnboarding() },
                onShowWhatsNew: { navigator.showWhatsNew() },
                onSendFeedback: { screens.ratingFlow.sendFeedback() }
            )
            .environment(screens.heartRateMonitor)
            .environment(screens.settingsStore)
            .environment(screens.mindfulMinutes)
            .environment(screens.appIconStore)
            .environment(screens.sessionHistory)
            .environment(\.auditionCue, screens.auditionCue)
        }
    }
}
