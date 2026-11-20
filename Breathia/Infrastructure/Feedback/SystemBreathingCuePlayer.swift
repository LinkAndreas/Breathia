#if os(iOS)
import UIKit
#endif

/// Plays a haptic tap and/or a sound at each phase change, according to the
/// user's settings. Macs have no Taptic Engine, so they only play sounds.
struct SystemBreathingCuePlayer: BreathingCuePlaying {
    private let hapticsEnabled: Bool
    private let soundEnabled: Bool
    private let sound: CueSound
    private let volume: Double
    private let sounds: CueSoundPlayer

    #if os(iOS)
    private let inhaleTap = UIImpactFeedbackGenerator(style: .medium)
    private let otherTap = UIImpactFeedbackGenerator(style: .light)
    #endif

    init(settings: AppSettings, sounds: CueSoundPlayer) {
        hapticsEnabled = settings.hapticsEnabled
        soundEnabled = settings.soundEnabled && settings.cueVolume > 0
        sound = settings.cueSound
        volume = settings.cueVolume
        self.sounds = sounds
    }

    func preload(_ phases: [BreathPhase]) {
        guard soundEnabled else { return }
        sounds.preload(phases, sound: sound)
    }

    /// Wakes the Taptic Engine and starts the audio engine. Without this, the first
    /// tap starts it up on the main thread and stalls whatever is on screen then.
    func prepare() {
        #if os(iOS)
        if hapticsEnabled {
            inhaleTap.prepare()
            otherTap.prepare()
        }
        #endif
        if soundEnabled { sounds.prepare() }
    }

    func cue(_ phase: BreathPhase) {
        #if os(iOS)
        if hapticsEnabled {
            let tap = phase.kind == .inhale ? inhaleTap : otherTap
            tap.impactOccurred()
            tap.prepare() // Stay ready for the next phase.
        }
        #endif
        if soundEnabled {
            sounds.play(phase, sound: sound, volume: volume)
        }
    }

    func stop() {
        if soundEnabled { sounds.stop() }
    }
}
