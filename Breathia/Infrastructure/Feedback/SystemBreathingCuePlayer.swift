#if os(iOS)
import AudioToolbox
import UIKit
#endif

/// Plays a haptic tap and/or a soft sound at each phase change, according to the
/// user's settings. Macs have no Taptic Engine, so they only play sounds — soft
/// chimes, since the Mac's system sounds are alerts.
struct SystemBreathingCuePlayer: BreathingCuePlaying {
    private let hapticsEnabled: Bool
    private let soundEnabled: Bool

    #if os(iOS)
    private static let tink: SystemSoundID = 1103
    private static let tock: SystemSoundID = 1104
    private let inhaleTap = UIImpactFeedbackGenerator(style: .medium)
    private let otherTap = UIImpactFeedbackGenerator(style: .light)
    #elseif os(macOS)
    private let chimes = ChimePlayer()
    #endif

    init(hapticsEnabled: Bool, soundEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
    }

    /// Wakes the Taptic Engine. Without this, the first tap starts it up on the
    /// main thread and stalls whatever is on screen at that moment.
    func prepare() {
        #if os(iOS)
        guard hapticsEnabled else { return }
        inhaleTap.prepare()
        otherTap.prepare()
        #elseif os(macOS)
        // Starts the audio engine before the first cue.
        if soundEnabled { chimes.prepare() }
        #endif
    }

    func cue(_ phase: BreathPhase) {
        #if os(iOS)
        if hapticsEnabled {
            let tap = phase.kind == .inhale ? inhaleTap : otherTap
            tap.impactOccurred()
            tap.prepare() // Stay ready for the next phase.
        }
        if soundEnabled {
            let sound = phase.kind == .inhale ? Self.tink : Self.tock
            // The first system sound loads the audio services; off the main thread
            // that can never hold up the UI.
            Task.detached(priority: .userInitiated) {
                AudioServicesPlaySystemSound(sound)
            }
        }
        #elseif os(macOS)
        if soundEnabled {
            switch phase.kind {
            case .inhale: chimes.play(.inhale)
            case .hold: chimes.play(.hold)
            case .exhale: chimes.play(.exhale)
            }
        }
        #endif
    }
}
