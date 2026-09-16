import Foundation

/// Where a running session shows outside the app — on iPhone, a Live Activity on
/// the Lock Screen and in the Dynamic Island.
protocol SessionActivityReporting {
    /// Connects the activity's controls (pause, resume, end) to the session.
    func bindControls(pause: @escaping () -> Void, resume: @escaping () -> Void, end: @escaping () -> Void)
    /// Shows the session's current state; the first call starts the activity.
    func update(_ snapshot: SessionActivitySnapshot)
    /// Removes the activity once the session has ended or was left.
    func end()
}

extension SessionActivityReporting {
    func bindControls(pause: @escaping () -> Void, resume: @escaping () -> Void, end: @escaping () -> Void) {}
}

/// A running session's state at one moment. Sent when the session starts and on
/// pause or resume; the activity's progress bar fills by itself in between.
struct SessionActivitySnapshot {
    let technique: Technique
    let sessionEndDate: Date
    let remaining: TimeInterval
    let isPaused: Bool
}

/// For devices without Live Activities, such as Apple Watch.
struct NoSessionActivity: SessionActivityReporting {
    func update(_ snapshot: SessionActivitySnapshot) {}
    func end() {}
}
