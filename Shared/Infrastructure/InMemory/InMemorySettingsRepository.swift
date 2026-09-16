// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// `SettingsRepository` held in memory — for previews and tests.
final class InMemorySettingsRepository: SettingsRepository {
    private var settings: AppSettings

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
    }

    func loadSettings() -> AppSettings { settings }
    func saveSettings(_ settings: AppSettings) { self.settings = settings }
}
#endif
