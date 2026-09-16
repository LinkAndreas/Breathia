#if canImport(WatchConnectivity)
import Foundation

/// iPhone side of the Apple Watch link: files sessions recorded on the watch into
/// History, and keeps the watch's copy of the settings current.
final class PhoneWatchSync {
    private var bridge: ConnectivityBridge?
    private var latestSettings: AppSettings?

    init(history: SessionHistory) {
        let bridge = ConnectivityBridge(
            onActivate: { [weak self] in
                self?.pushLatestSettings()
            },
            onReceive: { [weak history] key, data in
                guard key == SyncKey.session,
                      let record = try? JSONDecoder().decode(SessionRecord.self, from: data) else { return }
                history?.record(record)
            }
        )
        self.bridge = bridge
        bridge.activate()
    }

    func publish(_ settings: AppSettings) {
        latestSettings = settings
        pushLatestSettings()
    }

    private func pushLatestSettings() {
        guard let latestSettings, let data = try? JSONEncoder().encode(latestSettings) else { return }
        bridge?.updateContext(data, forKey: SyncKey.settings)
    }
}

/// Decorates a settings repository so every save is also sent to Apple Watch —
/// `SettingsStore` stays unaware that a watch exists.
struct WatchSyncingSettingsRepository: SettingsRepository {
    let base: SettingsRepository
    let sync: PhoneWatchSync

    func loadSettings() -> AppSettings {
        base.loadSettings()
    }

    func saveSettings(_ settings: AppSettings) {
        base.saveSettings(settings)
        sync.publish(settings)
    }
}
#endif
