// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// Individual stores for previews, backed by in-memory and simulated services,
/// so each preview provides only the stores its screen reads.
enum PreviewStores {
    static func heartRateMonitor() -> HeartRateMonitor {
        HeartRateMonitor(source: SimulatedHeartRateSource(), sensorName: "Polar H10")
    }

    static func sessionHistory(sessions: [SessionRecord] = PreviewData.sessions) -> SessionHistory {
        SessionHistory(repository: InMemorySessionRepository(sessions: sessions))
    }

    static func settingsStore() -> SettingsStore {
        SettingsStore(repository: InMemorySettingsRepository())
    }

    static func mindfulMinutes() -> MindfulMinutesStore {
        MindfulMinutesStore(service: InMemoryMindfulMinutesService())
    }

    /// Sessions with a simulated sensor, silent cues, and nowhere to keep results.
    static func sessionFactory() -> BreathingSessionFactory {
        let settings = Self.settingsStore()
        return BreathingSessionFactory(
            monitor: heartRateMonitor(),
            settingsStore: settings,
            source: .iPhone,
            recorder: SessionRecorder(keepingIn: { _ in }, mindfulMinutes: mindfulMinutes(), settingsStore: settings),
            makeCuePlayer: { _ in SilentBreathingCuePlayer() }
        )
    }
}
#endif
