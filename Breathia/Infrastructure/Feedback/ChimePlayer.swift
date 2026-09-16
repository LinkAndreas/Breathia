import AVFoundation
import OSLog

/// Soft, warm tones for breathing cues, synthesized once and played through an audio
/// engine. They swell in and fade slowly, like a singing bowl, so a phase change is
/// noticeable without sounding like an alert: no sharp attack, no metallic overtones.
final class ChimePlayer {
    /// Notes of a pentatonic scale, so any two in a row sound pleasant together:
    /// highest when breathing in, lowest when breathing out.
    enum Tone: CaseIterable {
        case inhale, hold, exhale

        var frequency: Double {
            switch self {
            case .inhale: 440.00 // A4
            case .hold: 392.00 // G4
            case .exhale: 329.63 // E4
            }
        }

        /// A hold is the quietest cue; nothing changes in the breath.
        var level: Double {
            self == .hold ? 0.7 : 1
        }
    }

    private static let duration = 1.6
    /// Players take turns, so a tone keeps ringing out when the next one starts —
    /// even in one-second phases — instead of being cut off or waiting its turn.
    private static let voiceCount = 3

    private let engine = AVAudioEngine()
    private let voices = (0..<ChimePlayer.voiceCount).map { _ in AVAudioPlayerNode() }
    private var nextVoice = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let buffers: [Tone: AVAudioPCMBuffer]
    private var isConnected = false
    private let logger = Logger(subsystem: "Breathia", category: "Cues")

    init() {
        let format = format
        buffers = Dictionary(uniqueKeysWithValues: Tone.allCases.map { ($0, Self.render($0, format: format)) })
        voices.forEach(engine.attach)
    }

    /// Starts the audio engine, so the first cue plays on time.
    func prepare() {
        guard !engine.isRunning else { return }
        do {
            if !isConnected {
                for voice in voices {
                    try engine.connectNode(voice, to: engine.mainMixerNode, format: format)
                }
                isConnected = true
            }
            try engine.start()
            for voice in voices {
                try voice.playAudio()
            }
        } catch {
            logger.error("Starting the audio engine failed: \(String(describing: error), privacy: .public)")
        }
    }

    func play(_ tone: Tone) {
        prepare()
        guard let buffer = buffers[tone] else { return }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        // The voice's previous tone started at least two cues ago and has faded out.
        voice.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    /// Two sine tones a few hertz apart, which beat slowly like a singing bowl, with a
    /// faint octave for warmth. A gentle swell in, then a long exponential fade that
    /// reaches silence by the end of the buffer.
    private static func render(_ tone: Tone, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let samples = buffer.floatChannelData![0]
        let frequency = tone.frequency
        let peak = 0.18 * tone.level / 1.6 // The partials add up to at most 1.6.
        for index in 0..<Int(frameCount) {
            let time = Double(index) / sampleRate
            // Raised-cosine swell: no click, no percussive edge.
            let attack = time < 0.07 ? 0.5 - 0.5 * cos(.pi * time / 0.07) : 1
            let release = min(1, (duration - time) / 0.3)
            let decay = exp(-time / 0.55)
            let body = sin(2 * .pi * frequency * time)
                + 0.5 * sin(2 * .pi * (frequency + 1.8) * time)
                + 0.1 * sin(2 * .pi * frequency * 2 * time) * exp(-time / 0.3)
            samples[index] = Float(peak * attack * release * decay * body)
        }
        return buffer
    }
}
