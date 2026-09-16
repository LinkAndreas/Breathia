import Foundation

/// `SettingsRepository` storing the settings as JSON in `UserDefaults`.
struct UserDefaultsSettingsRepository: SettingsRepository {
    private let storage: CodableDefaultsStorage<AppSettings>

    init(defaults: UserDefaults = .standard) {
        storage = CodableDefaultsStorage(key: "com.breathia.settings", defaults: defaults)
    }

    func loadSettings() -> AppSettings {
        storage.load() ?? AppSettings()
    }

    func saveSettings(_ settings: AppSettings) {
        storage.save(settings)
    }
}
