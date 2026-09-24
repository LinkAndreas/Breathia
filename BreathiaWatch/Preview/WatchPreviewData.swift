// Previews only; not part of the shipping app.
#if DEBUG
import Foundation

/// Sample data and sessions for the Watch app's SwiftUI previews.
enum WatchPreviewData {
    static let session = SessionRecord(
        id: UUID(),
        date: .now,
        techniqueID: "box",
        duration: 300,
        heartRate: HeartRateStats(start: 74, average: 68, end: 65),
        hrv: HRVStats(metric: .rmssd, average: 41, trend: .stable),
        heartRateTrace: [74, 72, 70, 69, 68, 67, 66, 65, 65, 65],
        source: .watch
    )

    /// Sessions with a steady simulated heart rate, silent cues, and nowhere to keep results.
    static func sessionFactory() -> BreathingSessionFactory {
        let settings = SettingsStore(repository: InMemorySettingsRepository())
        return BreathingSessionFactory(
            monitor: PreviewHeartRate(),
            settingsStore: settings,
            source: .watch,
            recorder: SessionRecorder(
                keepingIn: { _ in },
                mindfulMinutes: MindfulMinutesStore(service: InMemoryMindfulMinutesService()),
                settingsStore: settings
            ),
            makeCuePlayer: { _ in SilentBreathingCuePlayer() }
        )
    }
}

private final class PreviewHeartRate: LiveHeartRateProviding {
    let isConnected = true
    let heartRate: Int? = 66
    let hrv: HRV? = nil
}
#endif
