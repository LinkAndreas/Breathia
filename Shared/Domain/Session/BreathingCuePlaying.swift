import Foundation

/// Signals the start of each breathing phase to the user (haptics, sound).
protocol BreathingCuePlaying {
    /// Called during the countdown, so the first cue plays without a start-up delay
    /// holding up the switch to the live session.
    func prepare()
    /// Called once before the session starts with the technique's phases, so sounds
    /// that depend on a phase's length can be made ahead of time.
    func preload(_ phases: [BreathPhase])
    func cue(_ phase: BreathPhase)
    /// Silences any cue still sounding — on pause and when the session ends.
    func stop()
}

extension BreathingCuePlaying {
    func prepare() {}
    func preload(_ phases: [BreathPhase]) {}
    func stop() {}
}

struct SilentBreathingCuePlayer: BreathingCuePlaying {
    func cue(_ phase: BreathPhase) {}
}
