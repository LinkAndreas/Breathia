import Foundation

/// Watch side of the iPhone link: sends finished sessions to the phone's History
/// and applies settings changed on the phone.
final class WatchPhoneSync {
    private var bridge: ConnectivityBridge?

    init(settingsStore: SettingsStore) {
        let bridge = ConnectivityBridge(
            onActivate: {},
            onReceive: { [weak settingsStore] key, data in
                guard key == SyncKey.settings,
                      let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else { return }
                settingsStore?.settings = settings
            }
        )
        self.bridge = bridge
        bridge.activate()
    }

    func send(_ session: SessionRecord) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        bridge?.transfer(data, forKey: SyncKey.session)
    }
}
