import Foundation

/// Runs breathing sessions on Apple Watch. Each session is paired with a workout,
/// which supplies heart rate and keeps the app in front; the workout is kept in
/// Health only when the session was long enough to be recorded.
final class WatchSessionRunner {
    private let workout: WorkoutSessionControlling
    private let factory: BreathingSessionFactory
    private var activeSession: BreathingSessionModel?

    init(workout: WorkoutSessionControlling, factory: BreathingSessionFactory) {
        self.workout = workout
        self.factory = factory
    }

    /// Whether the Health permission sheet is still to come — explain it first.
    var needsAuthorization: Bool { workout.needsAuthorization }

    /// Shows the Health permission sheet. Call it after telling the user why, and
    /// before the session starts, so the prompt never interrupts a countdown.
    func requestAuthorization() async {
        await workout.requestAuthorization()
    }

    /// Starts the workout, then the session — unless it was closed meanwhile.
    func start(_ technique: Technique) -> BreathingSessionModel {
        let session = factory.makeSession(for: technique)
        activeSession = session
        Task {
            await workout.start()
            if activeSession === session {
                session.start()
            } else {
                await workout.stop(save: false)
            }
        }
        return session
    }

    /// Ends the workout once `session` has completed.
    func complete(_ session: BreathingSessionModel) {
        guard activeSession === session else { return }
        activeSession = nil
        Task { await workout.stop(save: session.wasRecorded) }
    }

    /// Closes `session` without completing it and discards its workout.
    func close(_ session: BreathingSessionModel) {
        session.cancel()
        guard activeSession === session else { return }
        activeSession = nil
        Task { await workout.stop(save: false) }
    }
}
