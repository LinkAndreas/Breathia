import Foundation

/// Where the user's preferences are kept. A domain contract: `SettingsStore`
/// depends on it; implementations live in Infrastructure.
protocol SettingsRepository {
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
}
