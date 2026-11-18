import SwiftUI

/// A settings page, given only the stores that page reads.
struct SettingsPageDestination: View {
    let page: SettingsPage
    let heartRateMonitor: HeartRateMonitor
    let settingsStore: SettingsStore
    let mindfulMinutes: MindfulMinutesStore
    let appIconStore: AppIconStore

    var body: some View {
        let detail = SettingsDetailView(page: page).id(page)
        switch page {
        case .sensor:
            detail.environment(heartRateMonitor)
        case .breathing, .biofeedback:
            detail.environment(settingsStore)
        case .appearance:
            detail.environment(settingsStore).environment(appIconStore)
        case .health:
            detail.environment(settingsStore).environment(mindfulMinutes)
        case .privacy, .aboutSensor:
            detail
        }
    }
}
