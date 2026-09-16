import Foundation

/// Builds the model for a new breathing session from the current settings, with
/// this device's heart-rate source, cue player, Live Activity, and recorder.
/// Session screens ask for a session and never see any of those.
final class BreathingSessionFactory {
    private let monitor: LiveHeartRateProviding
    private let settingsStore: SettingsStore
    private let source: SessionSource
    private let recorder: SessionRecorder
    private let makeCuePlayer: (AppSettings) -> BreathingCuePlaying
    private let makeActivity: () -> SessionActivityReporting

    init(
        monitor: LiveHeartRateProviding,
        settingsStore: SettingsStore,
        source: SessionSource,
        recorder: SessionRecorder,
        makeCuePlayer: @escaping (AppSettings) -> BreathingCuePlaying,
        makeActivity: @escaping () -> SessionActivityReporting = { NoSessionActivity() }
    ) {
        self.monitor = monitor
        self.settingsStore = settingsStore
        self.source = source
        self.recorder = recorder
        self.makeCuePlayer = makeCuePlayer
        self.makeActivity = makeActivity
    }

    func makeSession(for technique: Technique) -> BreathingSessionModel {
        let settings = settingsStore.settings
        let activity = makeActivity()
        let session = BreathingSessionModel(
            technique: technique,
            monitor: monitor,
            settings: settings,
            source: source,
            cuePlayer: makeCuePlayer(settings),
            activity: activity,
            onComplete: recorder.record
        )
        // The Live Activity's Pause and Stop buttons act on this session. Weak, so
        // the activity never keeps a finished session alive.
        activity.bindControls(
            pause: { [weak session] in session?.pause() },
            resume: { [weak session] in session?.resume() },
            end: { [weak session] in session?.end() }
        )
        return session
    }
}
