import Foundation

/// Renders the breathing cues as audio samples. Pure and deterministic, so the
/// sounds can be checked in tests without an audio device.
///
/// Every sound uses the same three notes of a G major pentatonic scale — D5 when
/// breathing in, B4 for a hold, G4 when breathing out — so any two cues in a row
/// sound consonant, and the rising and falling steps mirror the breath. The notes
/// sit high enough for small iPhone and iPad speakers, which barely reproduce
/// anything below 300 Hz.
///
/// The sounds aim to be soft and natural rather than electronic:
/// - Struck sounds are modelled from the vibration modes of the real instrument,
///   each mode ringing out on its own time, with the slow beating of the paired
///   modes a real bowl or bell has.
/// - They're struck with a soft mallet: a gentle onset, a muffled thump instead of
///   a click, and little energy in the upper modes.
/// - A small, warm room around every sound gives it space and a natural tail.
enum CueSynthesizer {
    static let sampleRate = 48_000.0

    /// The loudest a rendered cue gets: 6 dB under full scale. Cues ring on into
    /// the next phase, and in fast techniques several overlap; with this headroom
    /// they add up without reaching the limiter, which would make them rattle, and
    /// small iPhone speakers stay clear of distortion.
    static let peakLevel: Float = 0.5

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

    /// One vibration mode of a struck instrument: a sine at a multiple of the note's
    /// frequency that rings out on its own time. Real bowls and bells are never
    /// perfectly round, so each mode comes as a pair a fraction of a hertz apart,
    /// which beats slowly — the gentle pulsing of a ringing bowl.
    private struct Mode {
        let ratio: Double
        let amplitude: Double
        let decay: TimeInterval
        var beat: Double = 0
        /// How long the mode takes to speak. Upper modes of a soft mallet come in
        /// a little later than the fundamental, which softens the onset further.
        var attack: TimeInterval = 0
    }

    private struct Voicing {
        /// How long the instrument rings, before the room's tail.
        let duration: TimeInterval
        let modes: [Mode]
        /// The soft thump of the mallet: its loudness, and the highest frequency
        /// in it — felt and yarn mallets sound dull, never like a click.
        var thump: Double = 0
        var thumpCutoff: Double = 500
        /// How much of the room is heard, against the instrument itself.
        var room: Double = 0.3
    }

    nonisolated private static func voicing(of sound: CueSound) -> Voicing {
        switch sound {
        case .bowl:
            // A singing bowl struck with a felt mallet. The mode ratios of a
            // hammered bowl; the fundamental sings for seconds, the upper modes
            // fade early, so the sound grows rounder as it rings.
            Voicing(duration: 5.0, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 2.6, beat: 0.6, attack: 0.03),
                Mode(ratio: 2.76, amplitude: 0.32, decay: 1.4, beat: 1.4, attack: 0.04),
                Mode(ratio: 5.40, amplitude: 0.08, decay: 0.6, beat: 2.3, attack: 0.05),
                Mode(ratio: 8.93, amplitude: 0.02, decay: 0.25, attack: 0.05),
            ], thump: 0.05, thumpCutoff: 350, room: 0.32)
        case .bell:
            // A small handbell struck with a soft rubber mallet: a pure, round
            // tone with a quiet octave and twelfth, like a chime heard from across
            // a quiet room.
            Voicing(duration: 3.4, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 1.8, beat: 0.8, attack: 0.012),
                Mode(ratio: 2.01, amplitude: 0.26, decay: 1.0, beat: 1.1, attack: 0.018),
                Mode(ratio: 3.0, amplitude: 0.1, decay: 0.5, attack: 0.022),
                Mode(ratio: 4.18, amplitude: 0.035, decay: 0.2, attack: 0.025),
            ], thump: 0.04, thumpCutoff: 700, room: 0.3)
        case .wood:
            // A rosewood marimba bar under a yarn mallet: the tone is short, the
            // tube resonator below the bar carries the fundamental a little
            // longer, and the overtones barely sound.
            Voicing(duration: 1.6, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 0.42, attack: 0.008),
                Mode(ratio: 1, amplitude: 0.35, decay: 0.75, attack: 0.04),
                Mode(ratio: 3.98, amplitude: 0.12, decay: 0.07, attack: 0.01),
                Mode(ratio: 9.9, amplitude: 0.03, decay: 0.025, attack: 0.01),
            ], thump: 0.1, thumpCutoff: 300, room: 0.38)
        case .wave:
            // The wave's onset: a distant, softened bowl.
            Voicing(duration: 2.2, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 0.9, beat: 0.6, attack: 0.04),
                Mode(ratio: 2.76, amplitude: 0.18, decay: 0.45, attack: 0.05),
            ], room: 0)
        }
    }

    nonisolated private static func struck(_ sound: CueSound, kind: BreathPhase.Kind) -> [Float] {
        let voicing = voicing(of: sound)
        var samples = renderStruck(voicing, frequency: frequency(of: kind), tail: Room.tail)
        Room.apply(to: &samples, mix: voicing.room)
        fadeOut(&samples, over: 0.4)
        normalize(&samples, to: peakLevel * level(of: kind))
        return samples
    }

    /// The instrument alone, followed by `tail` seconds of silence for the room.
    nonisolated private static func renderStruck(_ voicing: Voicing, frequency: Double, tail: TimeInterval = 0) -> [Float] {
        let ringing = Int(voicing.duration * sampleRate)
        var samples = [Float](repeating: 0, count: ringing + Int(tail * sampleRate))
        var noise = NoiseGenerator()
        var thumpFilter = LowPass(cutoff: voicing.thumpCutoff)
        let thumpLength = 0.025
        for index in 0..<ringing {
            let time = Double(index) / sampleRate
            var value = 0.0
            for mode in voicing.modes {
                let envelope = mode.amplitude * exp(-time / mode.decay) * rise(time, over: mode.attack)
                guard envelope > 0.00005 else { continue }
                let phase = 2 * .pi * frequency * mode.ratio * time
                if mode.beat > 0 {
                    // The two halves of the pair, a few tenths of a hertz apart.
                    value += envelope * 0.5 * (sin(phase) + sin(phase + 2 * .pi * mode.beat * time))
                } else {
                    value += envelope * sin(phase)
                }
            }
            if voicing.thump > 0, time < thumpLength {
                let shape = sin(.pi * time / thumpLength)
                value += voicing.thump * thumpFilter.process(noise.next()) * shape * 8
            }
            // The ringing ends gently rather than being cut off.
            samples[index] = Float(value * fall(voicing.duration - time, over: 0.3))
        }
        return samples
    }

    // MARK: Wave

    /// A soft sound that lasts the whole phase, like a breath or a wave on a
    /// shore: filtered noise that brightens and swells while breathing in and
    /// darkens and recedes while breathing out, over a quiet tone that glides up
    /// and down between the two notes, so the phases can be told apart. A hold
    /// rests quietly where the breath ended. A distant bowl marks each turn.
    nonisolated private static func wave(_ request: Request) -> [Float] {
        let duration = Double(request.seconds)
        let count = Int(duration * sampleRate)
        let low = frequency(of: .exhale)
        let high = frequency(of: .inhale)
        let quiet = 0.3

        // (from, to) for pitch, loudness and brightness over the phase.
        let pitch: (Double, Double)
        let loudness: (Double, Double)
        let brightness: (Double, Double)
        switch request.kind {
        case .inhale:
            pitch = (low, high)
            loudness = (quiet, 1)
            brightness = (500, 1800)
        case .exhale:
            pitch = (high, low)
            loudness = (1, quiet)
            brightness = (1800, 500)
        case .hold:
            let note = request.endsFull ? high : low
            pitch = (note, note)
            loudness = request.endsFull ? (0.6, 0.6) : (quiet, quiet)
            brightness = request.endsFull ? (1100, 1100) : (600, 600)
        }

        var samples = [Float](repeating: 0, count: count)
        var noise = NoiseGenerator()
        var air = StateVariableFilter()
        var phase = 0.0
        var chorusPhase = 0.0
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let progress = smoothstep(time / duration)
            // The air: noise through a soft low-pass that opens with the breath.
            let cutoff = brightness.0 * pow(brightness.1 / brightness.0, progress)
            let breath = air.lowPass(noise.next(), cutoff: cutoff)
            // The tone glides in log frequency, so the step sounds even.
            let frequency = pitch.0 * pow(pitch.1 / pitch.0, progress)
            phase += 2 * .pi * frequency / sampleRate
            chorusPhase += 2 * .pi * (frequency + 0.5) / sampleRate
            let tone = 0.5 * (sin(phase) + sin(chorusPhase)) + 0.08 * sin(2 * phase)
            let amplitude = loudness.0 + (loudness.1 - loudness.0) * progress
            let edges = rise(time, over: 0.4) * fall(duration - time, over: 0.4)
            samples[index] = Float(amplitude * edges * (2.4 * breath + 0.22 * tone))
        }

        // The turn of the breath: a distant bowl on the phase's note.
        var accent = renderStruck(voicing(of: .wave), frequency: frequency(of: request.kind))
        normalize(&accent, to: 0.45)
        let body = samples.reduce(0) { max($0, abs($1)) }
        let accentLevel = body > 0 ? Float(0.5) * body / 0.45 : 1
        for index in 0..<min(accent.count, samples.count) {
            samples[index] += accent[index] * accentLevel * Float(fall(duration - Double(index) / sampleRate, over: 0.4))
        }

        Room.apply(to: &samples, mix: 0.25)
        fadeOut(&samples, over: 0.4)
        normalize(&samples, to: peakLevel * level(of: request.kind))
        return samples
    }

    // MARK: Room

    /// A small, warm room: a Schroeder–Moorer reverb with damped echoes, so the
    /// room's tail darkens as it fades, as in a room with soft furnishings.
    private enum Room {
        /// How long the room keeps sounding after the instrument stops.
        static let tail: TimeInterval = 1.4

        nonisolated static func apply(to samples: inout [Float], mix: Double) {
            guard mix > 0, !samples.isEmpty else { return }
            let scale = CueSynthesizer.sampleRate / 44_100
            var combs = [1116, 1188, 1277, 1356, 1422, 1491].map {
                Comb(length: Int(Double($0) * scale), feedback: 0.8, damping: 0.4)
            }
            var allPasses = [556, 441, 341].map { AllPass(length: Int(Double($0) * scale)) }
            let preDelay = Int(0.015 * CueSynthesizer.sampleRate)

            var wet = [Double](repeating: 0, count: samples.count)
            for index in samples.indices {
                let input = index >= preDelay ? Double(samples[index - preDelay]) : 0
                var value = 0.0
                for comb in combs.indices {
                    value += combs[comb].process(input)
                }
                for allPass in allPasses.indices {
                    value = allPasses[allPass].process(value)
                }
                wet[index] = value
            }

            // Mix by loudness rather than by a fixed gain, so every sound gets
            // the same amount of room whatever its spectrum.
            let dryLevel = rms(samples.map(Double.init))
            let wetLevel = rms(wet)
            guard dryLevel > 0, wetLevel > 0 else { return }
            let wetGain = mix * dryLevel / wetLevel
            let dryGain = 1 - 0.4 * mix
            for index in samples.indices {
                samples[index] = Float(Double(samples[index]) * dryGain + wet[index] * wetGain)
            }
        }

        nonisolated private static func rms(_ values: [Double]) -> Double {
            (values.reduce(0) { $0 + $1 * $1 } / Double(max(1, values.count))).squareRoot()
        }

        private struct Comb {
            private var buffer: [Double]
            private var index = 0
            private var store = 0.0
            let feedback: Double
            let damping: Double

            nonisolated init(length: Int, feedback: Double, damping: Double) {
                buffer = [Double](repeating: 0, count: max(1, length))
                self.feedback = feedback
                self.damping = damping
            }

            nonisolated mutating func process(_ input: Double) -> Double {
                let output = buffer[index]
                store = output * (1 - damping) + store * damping
                buffer[index] = input + store * feedback
                index = (index + 1) % buffer.count
                return output
            }
        }

        private struct AllPass {
            private var buffer: [Double]
            private var index = 0

            nonisolated init(length: Int) {
                buffer = [Double](repeating: 0, count: max(1, length))
            }

            nonisolated mutating func process(_ input: Double) -> Double {
                let delayed = buffer[index]
                buffer[index] = input + delayed * 0.5
                index = (index + 1) % buffer.count
                return delayed - input
            }
        }
    }

    // MARK: Helpers

    /// A raised-cosine rise from silence over `length` seconds.
    nonisolated private static func rise(_ time: Double, over length: Double) -> Double {
        guard length > 0, time < length else { return 1 }
        return 0.5 - 0.5 * cos(.pi * max(0, time) / length)
    }

    /// A raised-cosine fall to silence over the last `length` seconds, given the
    /// time `remaining`.
    nonisolated private static func fall(_ remaining: Double, over length: Double) -> Double {
        guard length > 0, remaining < length else { return 1 }
        return 0.5 - 0.5 * cos(.pi * max(0, remaining) / length)
    }

    /// Fades the end out, so a cue never stops with a click.
    nonisolated private static func fadeOut(_ samples: inout [Float], over seconds: Double) {
        let length = min(samples.count, Int(seconds * sampleRate))
        guard length > 0 else { return }
        for offset in 0..<length {
            let index = samples.count - length + offset
            samples[index] *= Float(fall(Double(length - offset - 1) / sampleRate, over: seconds))
        }
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

    /// A one-pole low-pass: takes the edge off the mallet's thump.
    private struct LowPass {
        private let coefficient: Double
        private var state = 0.0

        nonisolated init(cutoff: Double) {
            coefficient = 1 - exp(-2 * .pi * cutoff / CueSynthesizer.sampleRate)
        }

        nonisolated mutating func process(_ input: Double) -> Double {
            state += coefficient * (input - state)
            return state
        }
    }

    /// A gentle two-pole low-pass whose cutoff can move every sample, for the
    /// wave's air.
    private struct StateVariableFilter {
        private var low = 0.0
        private var band = 0.0

        nonisolated mutating func lowPass(_ input: Double, cutoff: Double) -> Double {
            let f = 2 * sin(.pi * min(cutoff, CueSynthesizer.sampleRate / 6) / CueSynthesizer.sampleRate)
            let damping = 1.2
            low += f * band
            let high = input - low - damping * band
            band += f * high
            return low
        }
    }

    /// The same noise every time, so a sound renders identically.
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
