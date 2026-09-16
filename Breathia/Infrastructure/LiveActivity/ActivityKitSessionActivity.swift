#if os(iOS) // ActivityKit is importable on macOS, but unavailable.
import ActivityKit
import OSLog
import SwiftUI

/// `SessionActivityReporting` as a Live Activity. One instance per session: the
/// first update starts the activity, later ones update it, `end()` removes it.
final class ActivityKitSessionActivity: SessionActivityReporting {
    private var activity: Activity<BreathingActivityAttributes>?
    /// The last update or end sent to ActivityKit. Each operation waits for the one
    /// before, so a quick pause and resume can't arrive in the wrong order.
    private var lastOperation: Task<Void, Never>?
    private let logger = Logger(subsystem: "Breathia", category: "LiveActivity")

    /// A session never survives the app being quit, so an activity still around at
    /// launch belongs to a session that's gone — remove it from the Lock Screen.
    static func endLeftoverActivities() {
        for activity in Activity<BreathingActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// The activity's Pause, Resume, and Stop buttons run intents in the app's
    /// process, which call these hooks.
    func bindControls(pause: @escaping () -> Void, resume: @escaping () -> Void, end: @escaping () -> Void) {
        LiveActivityActions.bind(to: self, pause: pause, resume: resume, end: end)
    }

    func update(_ snapshot: SessionActivitySnapshot) {
        let content = ActivityContent(
            state: BreathingActivityAttributes.ContentState(
                sessionEndDate: snapshot.sessionEndDate,
                remaining: snapshot.remaining,
                isPaused: snapshot.isPaused
            ),
            // If the app stops updating (e.g. it was quit) the activity is marked
            // outdated after the session's end — but never while paused, when the
            // end keeps moving.
            staleDate: snapshot.isPaused ? nil : snapshot.sessionEndDate.addingTimeInterval(60)
        )
        if let activity {
            enqueue { await activity.update(content) }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                let started = try Activity.request(attributes: Self.attributes(for: snapshot.technique), content: content)
                activity = started
                logger.info("Started Live Activity \(started.id, privacy: .public)")
            } catch {
                logger.error("Starting the Live Activity failed: \(String(describing: error), privacy: .public)")
            }
        } else {
            logger.notice("Live Activities are turned off for Breathia")
        }
    }

    func end() {
        LiveActivityActions.unbind(from: self)
        guard let activity else { return }
        self.activity = nil
        enqueue { await activity.end(nil, dismissalPolicy: .immediate) }
        logger.info("Ended Live Activity \(activity.id, privacy: .public)")
    }

    private func enqueue(_ operation: @escaping () async -> Void) {
        let previous = lastOperation
        lastOperation = Task {
            await previous?.value
            await operation()
        }
    }

    private static func attributes(for technique: Technique) -> BreathingActivityAttributes {
        let tint = technique.tint.resolve(in: EnvironmentValues())
        return BreathingActivityAttributes(
            techniqueName: technique.name,
            sessionDuration: TimeInterval(technique.recommendedDuration),
            tintRed: Double(tint.red),
            tintGreen: Double(tint.green),
            tintBlue: Double(tint.blue),
            pauseTitle: String(localized: "common.pause"),
            resumeTitle: String(localized: "common.resume"),
            endTitle: String(localized: "common.end")
        )
    }
}
#endif
