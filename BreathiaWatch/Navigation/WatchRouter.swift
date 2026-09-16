import Foundation
import Observation

struct WatchSessionLaunch: Identifiable {
    let id = UUID()
    let technique: Technique
}

@Observable
final class WatchRouter {
    var path: [Technique.ID] = []
    var activeSession: WatchSessionLaunch?

    func startSession(with technique: Technique) {
        activeSession = WatchSessionLaunch(technique: technique)
    }

    /// Leaves a session without a result (cancelled during the countdown).
    func dismissSession() {
        activeSession = nil
    }

    /// Leaves the summary and returns to the technique list.
    func finishSession() {
        activeSession = nil
        path = []
    }
}
