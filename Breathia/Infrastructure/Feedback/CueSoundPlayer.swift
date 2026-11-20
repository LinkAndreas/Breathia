import AVFoundation
import OSLog

/// Plays the breathing cues made by `CueSynthesizer` through an audio engine.
///
/// On iPhone and iPad the cues play as media: they follow the volume buttons and
/// the headphone volume, keep sounding with the ring/silent switch on — a closed-
/// eyes session relies on them — and mix with music or a podcast instead of
/// stopping it. One player serves the whole app, so a session and the preview in
/// Settings share one engine and one set of rendered sounds.
final class CueSoundPlayer {
    /// Voices take turns, so a cue keeps ringing out when the next one starts —
    /// even in one-second phases, where a voice comes round again after ten
    /// seconds, longer than any cue rings — instead of being cut off.
    private static let voiceCount = 10

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    /// Catches the rare peak when ringing cues overlap at full volume, so a loud
    /// setting never clips into a crackle.
    private let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    ))
    private let voices = (0..<CueSoundPlayer.voiceCount).map { _ in AVAudioPlayerNode() }
    private let format = AVAudioFormat(standardFormatWithSampleRate: CueSynthesizer.sampleRate, channels: 2)!
    private var buffers: [CueSynthesizer.Request: AVAudioPCMBuffer] = [:]
    private var nextVoice = 0
    /// Which of a cue's slightly different strikes plays next, so no two in a
    /// row sound exactly alike.
    private var nextVariant = 0
    private var isConnected = false
    private var audition: Task<Void, Never>?
    private let logger = Logger(subsystem: "Breathia", category: "Cues")

    /// Plugging in headphones, switching to AirPlay or a phone call stops the
    /// engine; `prepare()`, which every cue calls, starts it again on the new route.
    init() {
        engine.attach(mixer)
        engine.attach(limiter)
        voices.forEach(engine.attach)
    }

    // MARK: Playback

    /// Renders the cues a session will need, so none is made at the turn of a breath.
    func preload(_ phases: [BreathPhase], sound: CueSound) {
        for phase in phases {
            for variant in 0..<CueSynthesizer.variantCount {
                _ = buffer(for: CueSynthesizer.Request(sound: sound, phase: phase, variant: variant))
            }
        }
    }

    /// Starts the audio engine, so the first cue plays on time.
    func prepare() {
        guard !engine.isRunning else { return }
        do {
            try activateSession()
            if !isConnected {
                for voice in voices {
                    engine.connect(voice, to: mixer, format: format)
                }
                engine.connect(mixer, to: limiter, format: nil)
                engine.connect(limiter, to: engine.mainMixerNode, format: nil)
                isConnected = true
            }
            try engine.start()
            voices.forEach { $0.play() }
        } catch {
            logger.error("Starting the audio engine failed: \(String(describing: error), privacy: .public)")
        }
    }

    func play(_ phase: BreathPhase, sound: CueSound, volume: Double) {
        play(CueSynthesizer.Request(sound: sound, phase: phase, variant: nextVariant), volume: volume)
        nextVariant = (nextVariant + 1) % CueSynthesizer.variantCount
    }

    /// Silences every cue and lets other apps' audio return to full volume.
    func stop() {
        audition?.cancel()
        audition = nil
        voices.forEach { $0.stop() }
        guard engine.isRunning else { return }
        engine.stop()
        deactivateSession()
    }

    /// Plays a breath in and a breath out with the given sound and volume, so the
    /// choice can be heard in Settings.
    func audition(_ sound: CueSound, volume: Double) {
        audition?.cancel()
        voices.forEach { $0.stop() }
        // A sound that follows the breath is heard best over a few seconds;
        // struck sounds need less.
        let seconds = sound.lastsWholePhase ? 4 : 2
        let inhale = BreathPhase.inhale(seconds)
        let exhale = BreathPhase.exhale(seconds)
        audition = Task { [weak self] in
            self?.play(inhale, sound: sound, volume: volume)
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.play(exhale, sound: sound, volume: volume)
        }
    }

    private func play(_ request: CueSynthesizer.Request, volume: Double) {
        prepare()
        guard engine.isRunning else { return }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        if !voice.isPlaying { voice.play() }
        voice.volume = CueSynthesizer.gain(forVolume: volume)
        // The voice's previous cue started several cues ago and has rung out.
        voice.scheduleBuffer(buffer(for: request), at: nil, options: .interrupts)
    }

    private func buffer(for request: CueSynthesizer.Request) -> AVAudioPCMBuffer {
        if let buffer = buffers[request] { return buffer }
        let audio = CueSynthesizer.render(request)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audio.frameCount))!
        buffer.frameLength = AVAudioFrameCount(audio.frameCount)
        for (channel, samples) in [audio.left, audio.right].enumerated() {
            samples.withUnsafeBufferPointer { source in
                buffer.floatChannelData![channel].update(from: source.baseAddress!, count: samples.count)
            }
        }
        buffers[request] = buffer
        return buffer
    }

    // MARK: Audio session

    private func activateSession() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        #endif
    }

    private func deactivateSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.info("Deactivating the audio session failed: \(String(describing: error), privacy: .public)")
        }
        #endif
    }
}
