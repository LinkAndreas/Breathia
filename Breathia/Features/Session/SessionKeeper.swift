import Foundation

/// Keeps the running session alive while its screen is rebuilt.
///
/// On iPhone and iPad the session sits above the navigation layout, so a layout switch
/// leaves it alone. The Mac's session sheet hangs off the navigation stack, though, and
/// any screen can be rebuilt with new state. Without a keeper, a rebuilt screen would
/// start the session over.
///
/// The keeper hands every screen of one presentation the same session. It ends the
/// session when the user leaves it, or when no session screen has been on screen for
/// a moment — a dismissal the app didn't ask for, such as Escape on a Mac sheet.
final class SessionKeeper {
    /// How long the session waits for its screen to come back after it went away.
    /// A layout switch brings it back within a frame or two.
    static let gracePeriod: Duration = .seconds(1)

    private var session: BreathingSessionModel?
    private var screens = 0
    private var pendingRelease: Task<Void, Never>?

    /// Whether a session screen is showing.
    var isOnScreen: Bool { screens > 0 }

    /// Whether a session is being kept.
    var isHoldingSession: Bool { session != nil }

    /// The session on screen, made with `make` if there is none yet.
    func session(make: () -> BreathingSessionModel) -> BreathingSessionModel {
        if let session { return session }
        let session = make()
        self.session = session
        return session
    }

    /// A session screen appeared.
    func attach() {
        screens += 1
        pendingRelease?.cancel()
        pendingRelease = nil
    }

    /// A session screen disappeared. If none takes its place, the session ends.
    func detach() {
        screens = max(0, screens - 1)
        guard screens == 0, session != nil else { return }
        pendingRelease?.cancel()
        pendingRelease = Task { [weak self] in
            try? await Task.sleep(for: Self.gracePeriod)
            guard !Task.isCancelled, let self, self.screens == 0 else { return }
            self.release()
        }
    }

    /// Ends the session the user left — cancelled, or finished on the results screen.
    func release() {
        pendingRelease?.cancel()
        pendingRelease = nil
        if let session, !session.isCompleted {
            session.cancel()
        }
        session = nil
    }
}

private extension BreathingSessionModel {
    var isCompleted: Bool {
        if case .completed = stage { return true }
        return false
    }
}
