import WatchKit

/// Taps the wrist at each phase change: rising for inhale, falling for exhale,
/// a click for holds — so the session can be followed with eyes closed.
struct WatchBreathingCuePlayer: BreathingCuePlaying {
    let hapticsEnabled: Bool

    func cue(_ phase: BreathPhase) {
        guard hapticsEnabled else { return }
        let haptic: WKHapticType = switch phase.kind {
        case .inhale: .directionUp
        case .exhale: .directionDown
        case .hold: .click
        }
        WKInterfaceDevice.current().play(haptic)
    }
}
