import Foundation
import Observation

/// The user's preferences. Every change is written through to the repository.
@Observable
final class SettingsStore {
    var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            repository.saveSettings(settings)
        }
    }

    @ObservationIgnored private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
        self.settings = repository.loadSettings()
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
    }
}
