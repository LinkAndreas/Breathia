import Foundation

/// Where a session finished on this device goes: kept where the device keeps
/// sessions — History on iPhone, sent to iPhone's History on Apple Watch — and,
/// when the user allows it, saved to Apple Health as mindful minutes.
///
/// Sessions arriving on iPhone from Apple Watch skip this and go straight into
/// History; the watch saves its own mindful minutes, so they're never written twice.
final class SessionRecorder {
    private let keep: (SessionRecord) -> Void
    private let mindfulMinutes: MindfulMinutesStore
    private let settingsStore: SettingsStore

    init(
        keepingIn keep: @escaping (SessionRecord) -> Void,
        mindfulMinutes: MindfulMinutesStore,
        settingsStore: SettingsStore
    ) {
        self.keep = keep
        self.mindfulMinutes = mindfulMinutes
        self.settingsStore = settingsStore
    }

    func record(_ session: SessionRecord) {
        keep(session)
        guard settingsStore.settings.savesMindfulMinutes else { return }
        Task { await mindfulMinutes.save(session) }
    }
}
