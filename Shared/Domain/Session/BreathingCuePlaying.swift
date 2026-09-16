import Foundation

/// Signals the start of each breathing phase to the user (haptics, sound).
protocol BreathingCuePlaying {
    /// Called during the countdown, so the first cue plays without a start-up delay
    /// holding up the switch to the live session.
    func prepare()
    func cue(_ phase: BreathPhase)
}

extension BreathingCuePlaying {
    func prepare() {}
}

struct SilentBreathingCuePlayer: BreathingCuePlaying {
    func cue(_ phase: BreathPhase) {}
}
