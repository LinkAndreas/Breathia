#if os(iOS) // ActivityKit is importable on macOS, but unavailable.
import AppIntents
import Foundation

/// What the Live Activity's buttons do. The running session connects itself here
/// (`ActivityKitSessionActivity.bindControls`); the widget only knows the intents.
/// `LiveActivityIntent`s run in the app's process, even from the Lock Screen, so
/// they reach these hooks.
@MainActor
enum LiveActivityActions {
    static private(set) var pause: () -> Void = {}
    static private(set) var resume: () -> Void = {}
    static private(set) var end: () -> Void = {}
    /// The session activity the controls belong to.
    private static var owner: ObjectIdentifier?

    static func bind(
        to owner: AnyObject,
        pause: @escaping () -> Void,
        resume: @escaping () -> Void,
        end: @escaping () -> Void
    ) {
        self.owner = ObjectIdentifier(owner)
        self.pause = pause
        self.resume = resume
        self.end = end
    }

    /// Disconnects the controls — unless a newer session has bound them since, so
    /// a session that finishes late can't leave the next one's buttons dead.
    static func unbind(from owner: AnyObject) {
        guard self.owner == ObjectIdentifier(owner) else { return }
        self.owner = nil
        pause = {}
        resume = {}
        end = {}
    }
}

/// Pauses the running session from its Live Activity, without opening the app.
nonisolated struct PauseSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "liveActivity.pauseOrResume"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await MainActor.run { LiveActivityActions.pause() }
        return .result()
    }
}

/// Resumes the session from its Live Activity. Opens the app first: a session is
/// followed on screen, and in the background it would pause again right away.
nonisolated struct ResumeSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "liveActivity.pauseOrResume"
    static let isDiscoverable = false
    static let supportedModes: IntentModes = .foreground(.immediate)

    func perform() async throws -> some IntentResult {
        await MainActor.run { LiveActivityActions.resume() }
        return .result()
    }
}

/// Ends the running session from its Live Activity.
nonisolated struct EndSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "liveActivity.endSession"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await MainActor.run { LiveActivityActions.end() }
        return .result()
    }
}
#endif
