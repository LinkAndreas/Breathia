import Foundation

/// Renders the breathing cues as stereo audio. Pure and deterministic, so the
/// sounds can be checked in tests without an audio device.
///
/// Every sound uses the same three notes of a G major pentatonic scale — D5 when
/// breathing in, B4 for a hold, G4 when breathing out — so any two cues in a row
/// sound consonant, and the rising and falling steps mirror the breath. The notes
/// sit high enough for small iPhone and iPad speakers, which barely reproduce
/// anything below 300 Hz.
///
/// The sounds aim to be calm and natural rather than electronic:
/// - Struck sounds are modelled from the vibration modes of the real instrument,
///   each mode speaking and ringing out on its own time, with the slow beating of
///   the paired modes a real bowl or bell has.
/// - They're struck softly: a gentle onset and a muffled thump instead of a click.
/// - No two strikes are quite alike. Each cue comes in a few variants, a touch
///   apart in pitch, strength and brightness, as a hand would strike them.
/// - A warm room in stereo surrounds every sound, with a natural tail that
///   darkens as it fades.
/// - Every sound is equally loud, and none comes near full scale.
enum CueSynthesizer {
    static let sampleRate = 48_000.0

    /// The loudest a rendered cue gets: 6 dB under full scale. Cues ring on into
    /// the next phase, and in fast techniques several overlap; with this headroom
    /// they add up without reaching the limiter, which would make them rattle, and
    /// small iPhone speakers stay clear of distortion.
    static let peakLevel: Float = 0.5

    /// How many slightly different strikes each cue comes in.
    static let variantCount = 3

    /// A cue to render. Sounds that last the whole phase also need its length and
    /// whether the lungs are full at its end (which decides a hold's pitch).
    struct Request: Hashable {
        let sound: CueSound
        let kind: BreathPhase.Kind
        let seconds: Int
        let endsFull: Bool
        /// Which of the slightly different strikes; see `variantCount`.
        let variant: Int

        init(sound: CueSound, kind: BreathPhase.Kind, seconds: Int = 0, endsFull: Bool = false, variant: Int = 0) {
            self.sound = sound
            self.kind = kind
            // Only sounds that last the phase depend on it; struck sounds share one rendering.
            self.seconds = sound.lastsWholePhase ? max(1, seconds) : 0
            self.endsFull = sound.lastsWholePhase ? endsFull : false
            let count = CueSynthesizer.variantCount
            self.variant = ((variant % count) + count) % count
        }

        init(sound: CueSound, phase: BreathPhase, variant: Int = 0) {
            self.init(sound: sound, kind: phase.kind, seconds: phase.seconds, endsFull: phase.scale >= 1, variant: variant)
        }
    }

    /// A rendered cue: the two channels, equally long.
    struct Audio: Equatable {
        var left: [Float]
        var right: [Float]

        var frameCount: Int { left.count }

        /// The loudest sample in either channel.
        var peak: Float {
            max(left.reduce(0) { max($0, abs($1)) }, right.reduce(0) { max($0, abs($1)) })
        }
    }

    nonisolated static func render(_ request: Request) -> Audio {
        switch request.sound {
        case .bowl, .crystal, .bell, .kalimba, .wood:
            struck(request)
        case .chimes:
            chimes(request)
        case .wave:
            wave(request)
        case .ocean:
            ocean(request)
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
    /// perfectly round, so a mode can come as a pair a fraction of a hertz apart,
    /// which beats slowly — the gentle pulsing of a ringing bowl.
    private struct Mode {
        let ratio: Double
        let amplitude: Double
        let decay: TimeInterval
        var beat: Double = 0
        /// How long the mode takes to speak. Upper modes of a soft mallet come in
        /// a little later than the fundamental, which softens the onset.
        var attack: TimeInterval = 0
        /// An upper mode, which a harder or softer strike brings out more or less.
        var isUpper: Bool { ratio > 1.5 }
    }

    private struct Voicing {
        /// How long the instrument rings, before the room's tail.
        let duration: TimeInterval
        let modes: [Mode]
        /// The soft thump of the mallet or thumb: its loudness, and the highest
        /// frequency in it — felt and yarn sound dull, never like a click.
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
                Mode(ratio: 2.76, amplitude: 0.3, decay: 1.4, beat: 1.4, attack: 0.04),
                Mode(ratio: 5.40, amplitude: 0.07, decay: 0.6, beat: 2.3, attack: 0.05),
                Mode(ratio: 8.93, amplitude: 0.015, decay: 0.25, attack: 0.05),
            ], thump: 0.05, thumpCutoff: 350, room: 0.32)
        case .crystal:
            // A quartz crystal bowl touched with a suede mallet: almost a pure tone,
            // which blooms over a tenth of a second and lingers, with faint
            // harmonics and a very slow shimmer.
            Voicing(duration: 6.0, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 3.6, beat: 0.35, attack: 0.11),
                Mode(ratio: 2, amplitude: 0.1, decay: 1.8, beat: 0.5, attack: 0.14),
                Mode(ratio: 3, amplitude: 0.03, decay: 0.9, attack: 0.16),
            ], thump: 0.015, thumpCutoff: 250, room: 0.38)
        case .bell:
            // A small handbell struck with a soft rubber mallet: a pure, round
            // tone with a quiet octave and twelfth, like a chime heard from across
            // a quiet room.
            Voicing(duration: 3.4, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 1.8, beat: 0.8, attack: 0.012),
                Mode(ratio: 2.01, amplitude: 0.24, decay: 1.0, beat: 1.1, attack: 0.018),
                Mode(ratio: 3.0, amplitude: 0.09, decay: 0.5, attack: 0.022),
                Mode(ratio: 4.18, amplitude: 0.03, decay: 0.2, attack: 0.025),
            ], thump: 0.04, thumpCutoff: 700, room: 0.3)
        case .kalimba:
            // A kalimba tine plucked by a thumb: the tine's warm fundamental, its
            // high overtone that dies at once, and the wooden box answering below.
            Voicing(duration: 2.4, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 0.95, beat: 0.25, attack: 0.004),
                Mode(ratio: 2, amplitude: 0.05, decay: 0.35, attack: 0.006),
                Mode(ratio: 5.9, amplitude: 0.14, decay: 0.07, attack: 0.004),
                Mode(ratio: 0.5, amplitude: 0.07, decay: 0.18, attack: 0.008),
            ], thump: 0.05, thumpCutoff: 900, room: 0.3)
        case .wood:
            // A rosewood marimba bar under a yarn mallet: the tone is short, the
            // tube resonator below the bar carries the fundamental a little
            // longer, and the overtones barely sound.
            Voicing(duration: 1.6, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 0.42, attack: 0.008),
                Mode(ratio: 1, amplitude: 0.35, decay: 0.75, attack: 0.04),
                Mode(ratio: 3.98, amplitude: 0.11, decay: 0.07, attack: 0.01),
                Mode(ratio: 9.9, amplitude: 0.025, decay: 0.025, attack: 0.01),
            ], thump: 0.1, thumpCutoff: 300, room: 0.36)
        case .chimes:
            // One tube of a wind chime touched with a soft beater: the free bar's
            // modes, the upper ones short.
            Voicing(duration: 3.0, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 1.9, beat: 0.4, attack: 0.006),
                Mode(ratio: 2.76, amplitude: 0.3, decay: 0.8, beat: 0.9, attack: 0.008),
                Mode(ratio: 5.40, amplitude: 0.07, decay: 0.3, attack: 0.01),
            ], thump: 0.03, thumpCutoff: 1_500, room: 0.36)
        case .wave, .ocean:
            // The wave's onset: a distant, softened bowl.
            Voicing(duration: 2.2, modes: [
                Mode(ratio: 1, amplitude: 1, decay: 0.9, beat: 0.6, attack: 0.04),
                Mode(ratio: 2.76, amplitude: 0.16, decay: 0.45, attack: 0.05),
            ], room: 0)
        }
    }

    /// How a strike differs from the others: a few cents in pitch, a decibel or
    /// two in strength, and a softer or firmer touch.
    private struct Touch {
        let cents: Double
        let strength: Double
        let brightness: Double
        let seed: UInt32

        nonisolated static func variant(_ index: Int) -> Touch {
            switch index {
            case 1: Touch(cents: 4, strength: 0.9, brightness: 0.82, seed: 0x5BD1_E995)
            case 2: Touch(cents: -3, strength: 0.95, brightness: 1.12, seed: 0x27D4_EB2F)
            default: Touch(cents: 0, strength: 1, brightness: 1, seed: 0x9E37_79B9)
            }
        }
    }

    nonisolated private static func struck(_ request: Request) -> Audio {
        let voicing = voicing(of: request.sound)
        let touch = Touch.variant(request.variant)
        let dry = renderStruck(voicing, frequency: frequency(of: request.kind), touch: touch, tail: Room.tail)
        var audio = Audio(left: dry, right: dry)
        Room.apply(to: &audio, mix: voicing.room)
        return finish(audio, kind: request.kind, loudness: .struck, strength: touch.strength)
    }

    /// Three tubes of a wind chime, touched one after another: rising while
    /// breathing in, falling while breathing out, two for a hold. Each tube hangs
    /// a little to the left or right.
    nonisolated private static func chimes(_ request: Request) -> Audio {
        let voicing = voicing(of: .chimes)
        let touch = Touch.variant(request.variant)
        let note = frequency(of: request.kind)
        let steps: [Double] = switch request.kind {
        case .inhale: [1, 1.5, 2]
        case .exhale: [2, 1.5, 1]
        case .hold: [1, 1.5]
        }
        let offsets: [TimeInterval] = [0, 0.15 + 0.01 * Double(request.variant), 0.33]
        let strengths: [Double] = [1, 0.72, 0.55]
        let pans: [Double] = [-0.35, 0.3, -0.1]

        let length = Int((voicing.duration + offsets[2] + Room.tail) * sampleRate)
        var audio = Audio(left: [Float](repeating: 0, count: length), right: [Float](repeating: 0, count: length))
        for (index, step) in steps.enumerated() {
            let tube = renderStruck(voicing, frequency: note * step, touch: touch)
            let start = Int(offsets[index] * sampleRate)
            // Equal-power panning.
            let angle = (pans[index] + 1) * .pi / 4
            let left = Float(cos(angle) * strengths[index])
            let right = Float(sin(angle) * strengths[index])
            for offset in tube.indices where start + offset < length {
                audio.left[start + offset] += tube[offset] * left
                audio.right[start + offset] += tube[offset] * right
            }
        }
        Room.apply(to: &audio, mix: voicing.room)
        return finish(audio, kind: request.kind, loudness: .struck, strength: touch.strength)
    }

    /// The instrument alone, followed by `tail` seconds of silence for the room.
    nonisolated private static func renderStruck(
        _ voicing: Voicing,
        frequency: Double,
        touch: Touch = .variant(0),
        tail: TimeInterval = 0
    ) -> [Float] {
        let ringing = Int(voicing.duration * sampleRate)
        var samples = [Float](repeating: 0, count: ringing + Int(tail * sampleRate))
        var noise = NoiseGenerator(seed: touch.seed)
        var thumpFilter = LowPass(cutoff: voicing.thumpCutoff)
        let thumpLength = 0.025
        let pitch = frequency * pow(2, touch.cents / 1_200)
        let modes = voicing.modes.map { mode in
            (mode, mode.amplitude * (mode.isUpper ? touch.brightness : 1), 2 * Double.pi * pitch * mode.ratio)
        }
        for index in 0..<ringing {
            let time = Double(index) / sampleRate
            var value = 0.0
            for (mode, amplitude, angularFrequency) in modes {
                let envelope = amplitude * exp(-time / mode.decay) * rise(time, over: mode.attack)
                guard envelope > 0.00005 else { continue }
                let phase = angularFrequency * time
                if mode.beat > 0 {
                    // The two halves of the pair, a few tenths of a hertz apart.
                    value += envelope * 0.5 * (sin(phase) + sin(phase + 2 * .pi * mode.beat * time))
                } else {
                    value += envelope * sin(phase)
                }
            }
            if voicing.thump > 0, time < thumpLength {
                let shape = sin(.pi * time / thumpLength)
                value += voicing.thump * touch.brightness * thumpFilter.process(noise.next()) * shape * 8
            }
            // The ringing ends gently rather than being cut off.
            samples[index] = Float(value * fall(voicing.duration - time, over: 0.3))
        }
        return samples
    }

    // MARK: Wave

    /// A soft sound that lasts the whole phase, like a breath: air that brightens
    /// and swells while breathing in and darkens and recedes while breathing out,
    /// over a quiet tone that glides up and down between the two notes, so the
    /// phases can be told apart. A hold rests quietly where the breath ended. A
    /// distant bowl marks each turn.
    nonisolated private static func wave(_ request: Request) -> Audio {
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
            brightness = (500, 1_800)
        case .exhale:
            pitch = (high, low)
            loudness = (1, quiet)
            brightness = (1_800, 500)
        case .hold:
            let note = request.endsFull ? high : low
            pitch = (note, note)
            loudness = request.endsFull ? (0.6, 0.6) : (quiet, quiet)
            brightness = request.endsFull ? (1_100, 1_100) : (600, 600)
        }

        let touch = Touch.variant(request.variant)
        var audio = Audio(left: [Float](repeating: 0, count: count), right: [Float](repeating: 0, count: count))
        // Air on each side of its own, so the breath sounds wide, not from a point.
        var noiseLeft = NoiseGenerator(seed: touch.seed)
        var noiseRight = NoiseGenerator(seed: touch.seed &* 31 &+ 7)
        var airLeft = StateVariableFilter()
        var airRight = StateVariableFilter()
        var phase = 0.0
        var chorusPhase = 0.0
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let progress = smoothstep(time / duration)
            let cutoff = brightness.0 * pow(brightness.1 / brightness.0, progress)
            let breathLeft = airLeft.lowPass(noiseLeft.next(), cutoff: cutoff)
            let breathRight = airRight.lowPass(noiseRight.next(), cutoff: cutoff)
            // The tone glides in log frequency, so the step sounds even.
            let frequency = pitch.0 * pow(pitch.1 / pitch.0, progress)
            phase += 2 * .pi * frequency / sampleRate
            chorusPhase += 2 * .pi * (frequency + 0.5) / sampleRate
            let tone = 0.5 * (sin(phase) + sin(chorusPhase)) + 0.08 * sin(2 * phase)
            let amplitude = (loudness.0 + (loudness.1 - loudness.0) * progress)
                * rise(time, over: 0.4) * fall(duration - time, over: 0.4)
            audio.left[index] = Float(amplitude * (2.4 * breathLeft + 0.22 * tone))
            audio.right[index] = Float(amplitude * (2.4 * breathRight + 0.22 * tone))
        }

        // The turn of the breath: a distant bowl on the phase's note.
        var accent = renderStruck(voicing(of: .wave), frequency: frequency(of: request.kind), touch: touch)
        normalize(&accent, to: 1)
        let accentLevel = Float(0.5) * audio.peak
        for index in 0..<min(accent.count, count) {
            let value = accent[index] * accentLevel * Float(fall(duration - Double(index) / sampleRate, over: 0.4))
            audio.left[index] += value
            audio.right[index] += value
        }

        Room.apply(to: &audio, mix: 0.25)
        return finish(audio, kind: request.kind, loudness: .flowing, strength: 1)
    }

    // MARK: Ocean

    /// The sea on a quiet shore for the whole phase. Breathing in, a wave rolls
    /// in: a low rumble that grows and brightens. Breathing out, it breaks and
    /// washes back: a hiss of foam that fades as the water draws away. A hold is
    /// calm water lapping quietly. No tone at all — the sound of the water alone
    /// tells the phases apart.
    nonisolated private static func ocean(_ request: Request) -> Audio {
        let duration = Double(request.seconds)
        let count = Int(duration * sampleRate)

        // (from, to) for loudness and brightness of the water, and the foam's level.
        let loudness: (Double, Double)
        let brightness: (Double, Double)
        let foam: (Double, Double)
        switch request.kind {
        case .inhale:
            loudness = (0.25, 1)
            brightness = (280, 1_300)
            foam = (0, 0.15)
        case .exhale:
            loudness = (1, 0.2)
            brightness = (1_300, 320)
            foam = (0.7, 0)
        case .hold:
            let full = request.endsFull
            loudness = full ? (0.45, 0.4) : (0.25, 0.22)
            brightness = full ? (700, 650) : (420, 400)
            foam = full ? (0.08, 0.05) : (0, 0)
        }

        let touch = Touch.variant(request.variant)
        var audio = Audio(left: [Float](repeating: 0, count: count), right: [Float](repeating: 0, count: count))
        var pinkLeft = PinkNoise(seed: touch.seed)
        var pinkRight = PinkNoise(seed: touch.seed &* 31 &+ 7)
        var waterLeft = StateVariableFilter()
        var waterRight = StateVariableFilter()
        var foamLeft = HighPass(cutoff: 2_500)
        var foamRight = HighPass(cutoff: 2_500)
        var whiteLeft = NoiseGenerator(seed: touch.seed &+ 11)
        var whiteRight = NoiseGenerator(seed: touch.seed &+ 23)
        // The sea never moves evenly: a slow, irregular swell on top of the wave.
        let swellPhase = Double(request.variant) * 1.7
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let progress = smoothstep(time / duration)
            let swell = 1 + 0.12 * sin(2 * .pi * 0.13 * time + swellPhase) + 0.08 * sin(2 * .pi * 0.37 * time + 2 * swellPhase)
            let cutoff = brightness.0 * pow(brightness.1 / brightness.0, progress) * swell
            let level = (loudness.0 + (loudness.1 - loudness.0) * progress) * swell
            // Foam rises quickly as the wave breaks and fades as it draws back.
            let foamLevel = foam.0 + (foam.1 - foam.0) * progress.squareRoot()
            let edges = rise(time, over: 0.5) * fall(duration - time, over: 0.5)

            let left = waterLeft.lowPass(pinkLeft.next(), cutoff: cutoff) * level
                + foamLeft.process(whiteLeft.next()) * foamLevel * 0.25
            let right = waterRight.lowPass(pinkRight.next(), cutoff: cutoff * 0.94) * level
                + foamRight.process(whiteRight.next()) * foamLevel * 0.25
            audio.left[index] = Float(left * edges)
            audio.right[index] = Float(right * edges)
        }
        Room.apply(to: &audio, mix: 0.2)
        return finish(audio, kind: request.kind, loudness: .flowing, strength: 1)
    }

    // MARK: Finishing

    /// How loud a sound should feel. Sounds that last the whole phase are always
    /// there, so they sit a little lower than a strike.
    private enum Loudness {
        case struck, flowing

        /// The target level, as RMS over the part the ear judges loudness by.
        var target: Float {
            switch self {
            case .struck: 0.17
            case .flowing: 0.11
            }
        }
    }

    /// Fades the end, then brings the sound to its loudness — the same for every
    /// sound — without letting its peak above `peakLevel`.
    nonisolated private static func finish(_ audio: Audio, kind: BreathPhase.Kind, loudness: Loudness, strength: Double) -> Audio {
        var audio = audio
        fadeOut(&audio.left, over: 0.4)
        fadeOut(&audio.right, over: 0.4)

        // A strike is judged by its first second; a lasting sound by all of it.
        let window = loudness == .struck ? min(audio.frameCount, Int(sampleRate)) : audio.frameCount
        let energy = (audio.left.prefix(window).reduce(0) { $0 + $1 * $1 }
            + audio.right.prefix(window).reduce(0) { $0 + $1 * $1 }) / Float(max(1, 2 * window))
        let rms = energy.squareRoot()
        let peak = audio.peak
        guard rms > 0, peak > 0 else { return audio }

        let gain = min(loudness.target / rms, peakLevel / peak) * level(of: kind) * Float(strength)
        for index in 0..<audio.frameCount {
            audio.left[index] *= gain
            audio.right[index] *= gain
        }
        return audio
    }

    // MARK: Room

    /// A warm room in stereo: a feedback delay network of eight delay lines whose
    /// echoes blend densely, damped so the tail darkens as it fades, as in a room
    /// with soft furnishings. Each ear hears its own mix of the lines, which gives
    /// the room its width.
    private enum Room {
        /// How long the room keeps sounding after the instrument stops.
        static let tail: TimeInterval = 1.6
        /// The time the tail takes to fall by 60 dB.
        static let decayTime: TimeInterval = 1.8

        nonisolated static func apply(to audio: inout Audio, mix: Double) {
            guard mix > 0, audio.frameCount > 0 else { return }
            let sampleRate = CueSynthesizer.sampleRate
            let lengths = [1_433, 1_601, 1_867, 2_053, 2_251, 2_399, 2_687, 2_903]
            var lines = lengths.map { [Double](repeating: 0, count: $0) }
            var positions = [Int](repeating: 0, count: lengths.count)
            let gains = lengths.map { pow(10, -3 * Double($0) / (decayTime * sampleRate)) }
            var damping = [Double](repeating: 0, count: lengths.count)
            let dampingCoefficient = 0.4
            let preDelay = Int(0.02 * sampleRate)
            let signs: [Double] = [1, -1, 1, -1, 1, -1, 1, -1]

            var wetLeft = [Double](repeating: 0, count: audio.frameCount)
            var wetRight = [Double](repeating: 0, count: audio.frameCount)
            var outputs = [Double](repeating: 0, count: lengths.count)
            for index in 0..<audio.frameCount {
                let source = index >= preDelay
                    ? 0.5 * Double(audio.left[index - preDelay] + audio.right[index - preDelay])
                    : 0
                for line in lines.indices {
                    let delayed = lines[line][positions[line]]
                    damping[line] = delayed * (1 - dampingCoefficient) + damping[line] * dampingCoefficient
                    outputs[line] = damping[line]
                }
                wetLeft[index] = outputs[0] - outputs[2] + outputs[4] - outputs[6]
                wetRight[index] = outputs[1] - outputs[3] + outputs[5] - outputs[7]

                // Mix the lines with a Hadamard matrix, which spreads every echo
                // into every line and keeps the energy.
                hadamard(&outputs)
                for line in lines.indices {
                    lines[line][positions[line]] = outputs[line] * gains[line] + source * signs[line] * 0.35
                    positions[line] = (positions[line] + 1) % lengths[line]
                }
            }

            // Mix by loudness rather than by a fixed gain, so every sound gets the
            // same amount of room whatever its spectrum.
            let dryLevel = rms(audio.left) + rms(audio.right)
            let wetLevel = rms(wetLeft) + rms(wetRight)
            guard dryLevel > 0, wetLevel > 0 else { return }
            let wetGain = mix * dryLevel / wetLevel
            let dryGain = 1 - 0.4 * mix
            for index in 0..<audio.frameCount {
                audio.left[index] = Float(Double(audio.left[index]) * dryGain + wetLeft[index] * wetGain)
                audio.right[index] = Float(Double(audio.right[index]) * dryGain + wetRight[index] * wetGain)
            }
        }

        /// An 8-point fast Hadamard transform, scaled to keep the energy.
        nonisolated private static func hadamard(_ values: inout [Double]) {
            var size = 1
            while size < 8 {
                var start = 0
                while start < 8 {
                    for index in start..<(start + size) {
                        let a = values[index]
                        let b = values[index + size]
                        values[index] = a + b
                        values[index + size] = a - b
                    }
                    start += 2 * size
                }
                size *= 2
            }
            let scale = 1 / 8.0.squareRoot()
            for index in 0..<8 {
                values[index] *= scale
            }
        }

        nonisolated private static func rms(_ values: [Double]) -> Double {
            (values.reduce(0) { $0 + $1 * $1 } / Double(max(1, values.count))).squareRoot()
        }

        nonisolated private static func rms(_ values: [Float]) -> Double {
            (values.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(1, values.count))).squareRoot()
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

    /// A one-pole low-pass: takes the edge off a mallet's thump.
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

    /// A one-pole high-pass: the hiss of foam, without the water's rumble.
    private struct HighPass {
        private var lowPass: LowPass

        nonisolated init(cutoff: Double) {
            lowPass = LowPass(cutoff: cutoff)
        }

        nonisolated mutating func process(_ input: Double) -> Double {
            input - lowPass.process(input)
        }
    }

    /// A gentle two-pole low-pass whose cutoff can move every sample.
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

    /// The same noise every time for a seed, so a sound renders identically.
    private struct NoiseGenerator {
        private var state: UInt32

        nonisolated init(seed: UInt32 = 0x9E37_79B9) {
            state = seed
        }

        nonisolated mutating func next() -> Double {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Double(state) / Double(UInt32.max) * 2 - 1
        }
    }

    /// Pink noise — equal energy in every octave, as in surf and wind — made from
    /// white noise with Paul Kellet's filter.
    private struct PinkNoise {
        private var white: NoiseGenerator
        private var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0

        nonisolated init(seed: UInt32) {
            white = NoiseGenerator(seed: seed)
        }

        nonisolated mutating func next() -> Double {
            let w = white.next()
            b0 = 0.99886 * b0 + w * 0.0555179
            b1 = 0.99332 * b1 + w * 0.0750759
            b2 = 0.96900 * b2 + w * 0.1538520
            b3 = 0.86650 * b3 + w * 0.3104856
            b4 = 0.55000 * b4 + w * 0.5329522
            b5 = -0.7616 * b5 - w * 0.0168980
            let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362
            b6 = w * 0.115926
            return pink * 0.11
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
