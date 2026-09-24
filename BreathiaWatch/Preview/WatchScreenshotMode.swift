// App Store screenshots only; not part of the shipping app.
#if DEBUG
import Foundation

/// A screen to open for App Store screenshots, chosen with the launch argument
/// `-screenshot <screen>`. The app then runs with a simulated workout, so sessions
/// show a heart rate in the Simulator.
enum WatchScreenshotScreen: String {
    /// The technique list.
    case list
    /// A technique's details.
    case technique
    /// A live session.
    case session
    /// A finished session's summary.
    case summary

    /// The screen asked for at launch, if any.
    static let requested: WatchScreenshotScreen? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), index + 1 < arguments.count else { return nil }
        return WatchScreenshotScreen(rawValue: arguments[index + 1])
    }()

    /// The technique the technique page and the session show.
    static let techniqueID: Technique.ID = "resonance"
}

extension WatchDependencies {
    /// The watch app with a simulated workout and nothing kept, for screenshots.
    static func screenshots() -> WatchDependencies {
        WatchDependencies(
            settingsRepository: InMemorySettingsRepository(),
            workout: ScreenshotWorkout(),
            mindfulMinutesService: InMemoryMindfulMinutesService()
        )
    }
}

extension WatchRouter {
    /// Opens the screen asked for with `-screenshot`.
    func showForScreenshots() {
        let technique = TechniqueCatalog.technique(withID: WatchScreenshotScreen.techniqueID)
        switch WatchScreenshotScreen.requested {
        case .technique: path = [technique.id]
        case .session: startSession(with: technique)
        case .list, .summary, nil: break
        }
    }
}

/// A workout that is always allowed and reports a heart rate rising and falling
/// with the breath, as a calm session would.
private final class ScreenshotWorkout: WorkoutSessionControlling {
    private let start = Date()

    let isConnected = true
    let needsAuthorization = false

    var heartRate: Int? {
        let seconds = Date().timeIntervalSince(start)
        return Int((66 + 4 * sin(2 * .pi * seconds / 10)).rounded())
    }

    var hrv: HRV? {
        HRV(sdnn: 48, rmssd: 42 + 3 * sin(Date().timeIntervalSince(start) / 7))
    }

    func requestAuthorization() async {}
    func start() async {}
    func stop(save: Bool) async {}
}
#endif
