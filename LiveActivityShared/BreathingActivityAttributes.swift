#if os(iOS) // ActivityKit is importable on macOS, but unavailable.
import ActivityKit
import Foundation

/// The Live Activity of a running breathing session. Compiled into the app, which
/// starts and updates it, and into the widget extension, which draws it.
nonisolated struct BreathingActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        /// When the session ends; the progress bar and elapsed time move toward it
        /// by themselves.
        var sessionEndDate: Date
        /// Time left in the session, for the frozen bar and elapsed time while paused.
        var remaining: TimeInterval
        var isPaused: Bool
    }

    var techniqueName: String
    /// The session's full length, shown as the total and used for the progress bar.
    var sessionDuration: TimeInterval
    /// The technique's colour as linear sRGB components, as SwiftUI resolves it —
    /// the extension doesn't share the app's colour palette.
    var tintRed: Double
    var tintGreen: Double
    var tintBlue: Double
    /// The buttons' accessibility labels, localized by the app — the extension has
    /// no string catalog of its own.
    var pauseTitle: String
    var resumeTitle: String
    var endTitle: String
}
#endif
