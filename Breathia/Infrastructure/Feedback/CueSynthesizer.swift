import Foundation

/// Renders the breathing cues as audio samples. Pure and deterministic, so the
/// sounds can be checked in tests without an audio device.
///
/// Every sound uses the same three notes of a G major pentatonic scale — D5 when
/// breathing in, B4 for a hold, G4 when breathing out — so any two cues in a row
/// sound consonant, and the rising and falling steps mirror the breath. The notes
/// sit higher than a typical chime on purpose: small iPhone and iPad speakers
/// barely reproduce anything below 300 Hz, and the ear is most sensitive between
/// 1 and 4 kHz, where each sound's overtones are placed to carry.
enum CueSynthesizer {
    static let sampleRate = 48_000.0

    /// The loudest a rendered cue gets, a little under full scale, so several
    /// overlapping cues stay clear of the limiter at normal volumes.
    static let peakLevel: Float = 0.89

    /// A cue to render. Sounds that last the whole phase also need its length and
    /// whether the lungs are full at its end (which decides a hold's pitch).
    struct Request: Hashable {
        let sound: CueSound
        let kind: BreathPhase.Kind
        let seconds: Int
        let endsFull: Bool

        init(sound: CueSound, kind: BreathPhase.Kind, seconds: Int = 0, endsFull: Bool = false) {
            self.sound = sound
            self.kind = kind
            // Only the wave depends on the phase; struck sounds share one rendering.
            self.seconds = sound == .wave ? max(1, seconds) : 0
            self.endsFull = sound == .wave ? endsFull : false
        }

        init(sound: CueSound, phase: BreathPhase) {
            self.init(sound: sound, kind: phase.kind, seconds: phase.seconds, endsFull: phase.scale >= 1)
        }
    }

    nonisolated static func render(_ request: Request) -> [Float] {
        switch request.sound {
        case .bowl, .bell, .wood:
            struck(request.sound, kind: request.kind)
        case .wave:
            wave(request)
        }
    }

    // MARK: Notes

    nonisolated static func frequency(of kind: BreathPhase.Kind) -> Double {
        switch kind {
        case .inhale: 587.33 // D5
        case .hold: 493.88 // B4
        case .exhale: 392.00 // G4
        }
    }

    /// A hold changes nothing in the breath, so its cue is the quietest — still
    /// clearly audible, about 3 dB down.
    nonisolated static func level(of kind: BreathPhase.Kind) -> Float {
        kind == .hold ? 0.7 : 1
    }

    // MARK: Struck sounds

    /// One component of a struck sound: a sine at a multiple of the note's frequency
    /// that rings out on its own time. A small detune adds a slow beat, like the
    /// shimmer of a real bowl or bell.
    private struct Partial {
        let ratio: Double
        let amplitude: Double
        let decay: TimeInterval
        var beat: Double = 0
    }

    private struct Voicing {
        let duration: TimeInterval
        let attack: TimeInterval
        let partials: [Partial]
        /// A few milliseconds of soft noise at the start, the sound of the mallet.
        var strike: Double = 0
    }

    nonisolated private static func voicing(of sound: CueSound) -> Voicing {
        switch sound {
        case .bowl:
            // Inharmonic modes of a singing bowl, struck with a felt mallet: a soft
            // onset, a long fundamental, and a shimmer from the paired modes.
            Voicing(duration: 3.0, attack: 0.012, partials: [
                Partial(ratio: 1, amplitude: 1, decay: 1.6, beat: 1.3),
                Partial(ratio: 2.71, amplitude: 0.55, decay: 0.95, beat: 2.1),
                Partial(ratio: 5.12, amplitude: 0.24, decay: 0.45),
                Partial(ratio: 8.22, amplitude: 0.09, decay: 0.22),
            ])
        case .bell:
            // A small church-bell spectrum: hum, prime, minor third, fifth and
            // nominal, with a bright strike that fades fast.
            Voicing(duration: 2.2, attack: 0.003, partials: [
                Partial(ratio: 0.5, amplitude: 0.22, decay: 1.5),
                Partial(ratio: 1, amplitude: 1, decay: 1.1, beat: 0.9),
                Partial(ratio: 1.19, amplitude: 0.32, decay: 0.75),
                Partial(ratio: 1.5, amplitude: 0.24, decay: 0.6),
                Partial(ratio: 2, amplitude: 0.62, decay: 0.7),
                Partial(ratio: 2.52, amplitude: 0.2, decay: 0.32),
                Partial(ratio: 3, amplitude: 0.16, decay: 0.22),
                Partial(ratio: 4.1, amplitude: 0.28, decay: 0.035),
            ], strike: 0.06)
        case .wood:
            // A rosewood bar under a soft mallet, tuned like a marimba: the
            // overtones sit at four and ten times the note and die almost at once.
            Voicing(duration: 0.8, attack: 0.002, partials: [
                Partial(ratio: 1, amplitude: 1, decay: 0.32),
                Partial(ratio: 3.93, amplitude: 0.42, decay: 0.08),
                Partial(ratio: 9.6, amplitude: 0.14, decay: 0.03),
            ], strike: 0.12)
        case .wave:
            // The wave's onset accent: a softened bowl.
            Voicing(duration: 1.6, attack: 0.02, partials: [
                Partial(ratio: 1, amplitude: 1, decay: 0.7, beat: 1.3),
                Partial(ratio: 2.71, amplitude: 0.4, decay: 0.4),
            ])
        }
    }

    nonisolated private static func struck(_ sound: CueSound, kind: BreathPhase.Kind) -> [Float] {
        var samples = renderStruck(voicing(of: sound), frequency: frequency(of: kind))
        normalize(&samples, to: peakLevel * level(of: kind))
        return samples
    }

    nonisolated private static func renderStruck(_ voicing: Voicing, frequency: Double) -> [Float] {
        let count = Int(voicing.duration * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        let release = 0.06
        var noise = NoiseGenerator()
        for index in 0..<count {
            let time = Double(index) / sampleRate
            var value = 0.0
            for partial in voicing.partials {
                let envelope = partial.amplitude * exp(-time / partial.decay)
                guard envelope > 0.0001 else { continue }
                let phase = 2 * .pi * frequency * partial.ratio * time
                value += envelope * sin(phase)
                if partial.beat > 0 {
                    value += 0.6 * envelope * sin(phase + 2 * .pi * partial.beat * time)
                }
            }
            if voicing.strike > 0, time < 0.012 {
                value += voicing.strike * noise.next() * (1 - time / 0.012)
            }
            samples[index] = Float(value * edges(time, length: voicing.duration, attack: voicing.attack, release: release))
        }
        return samples
    }

    // MARK: Wave

    /// A soft, chorused tone that lasts the whole phase. Breathing in, it glides up
    /// from the out-breath note to the in-breath note and swells; breathing out, it
    /// glides back down and recedes; a hold rests on the note the breath ended on.
    /// A softened bowl strike marks the start of each phase.
    nonisolated private static func wave(_ request: Request) -> [Float] {
        let duration = Double(request.seconds)
        let count = Int(duration * sampleRate)
        let low = frequency(of: .exhale)
        let high = frequency(of: .inhale)
        let quiet = 0.42

        // (from, to) for pitch and loudness over the phase.
        let pitch: (Double, Double)
        let loudness: (Double, Double)
        switch request.kind {
        case .inhale:
            pitch = (low, high)
            loudness = (quiet, 1)
        case .exhale:
            pitch = (high, low)
            loudness = (1, quiet)
        case .hold:
            let note = request.endsFull ? high : low
            pitch = (note, note)
            loudness = request.endsFull ? (0.8, 0.8) : (quiet, quiet)
        }

        var samples = [Float](repeating: 0, count: count)
        var phase = 0.0
        var chorusPhase = 0.0
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let progress = smoothstep(time / duration)
            // Glide in log frequency, so the step sounds even all the way through.
            let frequency = pitch.0 * pow(pitch.1 / pitch.0, progress)
            phase += 2 * .pi * frequency / sampleRate
            chorusPhase += 2 * .pi * (frequency + 0.8) / sampleRate
            let body = sin(phase) + 0.35 * sin(2 * phase) + 0.12 * sin(3 * phase) + 0.5 * sin(chorusPhase)
            let amplitude = loudness.0 + (loudness.1 - loudness.0) * progress
            samples[index] = Float(amplitude * body * edges(time, length: duration, attack: 0.15, release: 0.2))
        }
        normalize(&samples, to: 0.62)

        // The accent marks the turn of the breath, quieter than the struck sounds.
        var accent = renderStruck(voicing(of: .wave), frequency: frequency(of: request.kind))
        normalize(&accent, to: 0.3 * level(of: request.kind))
        for index in 0..<min(accent.count, samples.count) {
            samples[index] += accent[index]
        }
        normalize(&samples, to: peakLevel * level(of: request.kind))
        return samples
    }

    // MARK: Helpers

    /// A raised-cosine fade in and out, so a cue never starts or stops with a click.
    nonisolated private static func edges(_ time: Double, length: Double, attack: Double, release: Double) -> Double {
        let fadeIn = time < attack ? 0.5 - 0.5 * cos(.pi * time / attack) : 1
        let remaining = length - time
        let fadeOut = remaining < release ? 0.5 - 0.5 * cos(.pi * max(0, remaining) / release) : 1
        return fadeIn * fadeOut
    }

    nonisolated private static func smoothstep(_ value: Double) -> Double {
        let x = min(1, max(0, value))
        return x * x * (3 - 2 * x)
    }

    nonisolated private static func normalize(_ samples: inout [Float], to peak: Float) {
        let current = samples.reduce(0) { max($0, abs($1)) }
        guard current > 0 else { return }
        let gain = peak / current
        for index in samples.indices {
            samples[index] *= gain
        }
    }

    /// The same short burst of noise every time, so a sound renders identically.
    private struct NoiseGenerator {
        private var state: UInt32 = 0x9E37_79B9

        nonisolated mutating func next() -> Double {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Double(state) / Double(UInt32.max) * 2 - 1
        }
    }
}

extension CueSynthesizer {
    /// The gain for a volume setting from 0 to 1: a 30 dB range on a decibel
    /// scale, which the ear hears as evenly spaced steps, and silence at 0.
    nonisolated static func gain(forVolume volume: Double) -> Float {
        let volume = min(1, max(0, volume))
        guard volume > 0 else { return 0 }
        return Float(pow(10, (-30 + 30 * volume) / 20))
    }
}
