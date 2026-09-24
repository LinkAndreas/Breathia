import SwiftUI

/// A settings page, given only the stores that page reads.
struct SettingsPageDestination: View {
    let page: SettingsPage
    let heartRateMonitor: HeartRateMonitor
    let settingsStore: SettingsStore
    let mindfulMinutes: MindfulMinutesStore

    var body: some View {
        let detail = SettingsDetailView(page: page).id(page)
        switch page {
        case .sensor:
            detail.environment(heartRateMonitor)
        case .breathing, .biofeedback, .appearance:
            detail.environment(settingsStore)
        case .health:
            detail.environment(settingsStore).environment(mindfulMinutes)
        case .privacy, .aboutSensor:
            detail
        }
    }
}
