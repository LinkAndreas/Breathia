// App Store screenshots only; not part of the shipping app.
#if DEBUG
import Foundation

/// A screen to open for App Store screenshots, chosen with the launch argument
/// `-screenshot <screen>`. The app then starts with sample sessions and the
/// simulated sensor already connected, and opens that screen.
enum ScreenshotScreen: String {
    /// The technique list.
    case breathe
    /// A technique's explanations.
    case technique
    /// A live session with biofeedback.
    case session
    /// The History list.
    case history
    /// A past session's report.
    case historyDetail
    /// A past session's report, scrolled down to the charts of each breath and HRV.
    case historyCharts
    /// Settings.
    case settings
    /// The sensor sheet with the sensor connected.
    case sensor
    /// Settings' Version History page.
    case versionHistory

    /// The screen asked for at launch, if any.
    static let requested: ScreenshotScreen? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), index + 1 < arguments.count else { return nil }
        return ScreenshotScreen(rawValue: arguments[index + 1])
    }()

    /// The technique the technique page and the session show.
    static let techniqueID: Technique.ID = "resonance"

    /// Light unless `-screenshotAppearance dark` asks for dark, whatever the system
    /// appearance, so every platform's screenshots match.
    static let appearance: Appearance = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshotAppearance"), index + 1 < arguments.count else { return .light }
        return Appearance(rawValue: arguments[index + 1]) ?? .light
    }()
}

extension AppDependencies {
    /// The app with sample sessions and a connected simulated sensor, for screenshots.
    static func screenshots() -> AppDependencies {
        let sensor = SimulatedHeartRateSource(defaults: UserDefaults(suiteName: "screenshots") ?? .standard)
        let dependencies = preview(heartRateSource: sensor)
        dependencies.settingsStore.settings.appearance = ScreenshotScreen.appearance
        sensor.connectImmediately()
        return dependencies
    }
}

extension SimulatedHeartRateSource {
    /// Skips permission and scanning and starts streaming right away.
    func connectImmediately() {
        grantPermission()
        startStreaming()
    }
}

#if os(macOS)
import AppKit

extension ScreenshotScreen {
    /// 2880 × 1800 pixels on a Retina display — the App Store's Mac screenshot size.
    static let windowSize = CGSize(width: 1440, height: 900)

    /// Gives the window exactly `windowSize`, whatever size it was left at before.
    @MainActor
    static func sizeWindow() async {
        guard requested != nil else { return }
        try? await Task.sleep(for: .seconds(1.5))
        guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: \.canBecomeMain) else { return }
        window.setFrame(NSRect(origin: CGPoint(x: 20, y: 20), size: windowSize), display: true)
    }
}
#endif
#endif
