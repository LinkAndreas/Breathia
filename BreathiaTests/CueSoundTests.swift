import Foundation
import Testing
@testable import Breathia

/// Off the main actor: rendering is slow in a debug build and would hold up
/// tests that run on it.
nonisolated struct CueSynthesizerTests {
    private static let kinds: [BreathPhase.Kind] = [.inhale, .hold, .exhale]

    private func rms(_ samples: ArraySlice<Float>) -> Float {
        (samples.reduce(0) { $0 + $1 * $1 } / Float(max(1, samples.count))).squareRoot()
    }

    @Test(arguments: CueSound.allCases)
    func everyCueIsAudibleAndNeverClips(sound: CueSound) {
        for kind in Self.kinds {
            let audio = CueSynthesizer.render(.init(sound: sound, kind: kind, seconds: 4))
            #expect(audio.frameCount > 0)
            #expect(audio.left.count == audio.right.count)
            let allFinite = audio.left.allSatisfy { $0.isFinite } && audio.right.allSatisfy { $0.isFinite }
            #expect(allFinite)
            #expect(audio.peak <= CueSynthesizer.peakLevel + 0.0001)
            // Far louder than the old chime, which peaked around 0.11.
            #expect(audio.peak >= 0.2)
        }
    }

    /// No click: every cue fades in from silence and out to silence.
    @Test(arguments: CueSound.allCases)
    func cuesStartAndEndInSilence(sound: CueSound) {
        for kind in Self.kinds {
            let audio = CueSynthesizer.render(.init(sound: sound, kind: kind, seconds: 4))
            for channel in [audio.left, audio.right] {
                #expect(abs(channel.first ?? 1) < 0.01)
                #expect(abs(channel.last ?? 1) < 0.01)
            }
        }
    }

    @Test(arguments: CueSound.allCases)
    func holdIsQuieterThanBreathing(sound: CueSound) {
        let inhale = CueSynthesizer.render(.init(sound: sound, kind: .inhale, seconds: 4))
        let hold = CueSynthesizer.render(.init(sound: sound, kind: .hold, seconds: 4))
        #expect(rms(hold.left[...]) < rms(inhale.left[...]))
    }

    /// Every sound feels about as loud as the others of its kind, so switching
    /// doesn't startle. Sounds that last the whole phase sit a little lower, as
    /// they're always there.
    @Test(arguments: [CueSound.struck, CueSound.flowing])
    func soundsOfAKindAreAboutEquallyLoud(sounds: [CueSound]) {
        let levels = sounds.map { sound in
            let audio = CueSynthesizer.render(.init(sound: sound, kind: .inhale, seconds: 4))
            let window = sound.lastsWholePhase ? audio.frameCount : Int(CueSynthesizer.sampleRate)
            return 20 * log10(Double(rms(audio.left.prefix(window))))
        }
        #expect((levels.max() ?? 0) - (levels.min() ?? 0) < 3)
    }

    /// Strikes differ a little from each other, as by hand, but stay the same note.
    @Test func variantsDifferSlightly() {
        let first = CueSynthesizer.render(.init(sound: .bowl, kind: .inhale, variant: 0))
        let second = CueSynthesizer.render(.init(sound: .bowl, kind: .inhale, variant: 1))
        #expect(first != second)
        #expect(CueSynthesizer.Request(sound: .bowl, kind: .inhale, variant: 4).variant == 1)
    }

    /// The room makes the sound wide: the two sides aren't the same.
    @Test func cuesAreInStereo() {
        let audio = CueSynthesizer.render(.init(sound: .crystal, kind: .inhale))
        #expect(audio.left != audio.right)
    }

    /// Cues that ring on into the next ones, as in a breath a second, add up
    /// without reaching full scale, where the limiter would make them rattle.
    @Test(arguments: CueSound.allCases)
    func overlappingCuesStayClearOfFullScale(sound: CueSound) {
        for seconds in [1, 2, 3] {
            // Rendered once each: rendering is slow in a debug build.
            let inhale = CueSynthesizer.render(.init(sound: sound, kind: .inhale, seconds: seconds))
            let exhale = CueSynthesizer.render(.init(sound: sound, kind: .exhale, seconds: seconds, variant: 1))
            var mix = [Float](repeating: 0, count: Int(CueSynthesizer.sampleRate) * 12)
            var start = 0
            var index = 0
            while start < mix.count {
                let samples = index.isMultiple(of: 2) ? inhale.left : exhale.left
                for offset in samples.indices where start + offset < mix.count {
                    mix[start + offset] += samples[offset]
                }
                start += seconds * Int(CueSynthesizer.sampleRate)
                index += 1
            }
            #expect(mix.reduce(0) { max($0, abs($1)) } < 0.9)
        }
    }

    @Test func notesRiseForInhaleAndFallForExhale() {
        #expect(CueSynthesizer.frequency(of: .inhale) > CueSynthesizer.frequency(of: .hold))
        #expect(CueSynthesizer.frequency(of: .hold) > CueSynthesizer.frequency(of: .exhale))
        // High enough to carry on small speakers.
        #expect(CueSynthesizer.frequency(of: .exhale) >= 300)
    }

    @Test(arguments: CueSound.flowing)
    func flowingSoundsLastTheWholePhase(sound: CueSound) {
        let audio = CueSynthesizer.render(.init(sound: sound, kind: .inhale, seconds: 5))
        #expect(audio.frameCount == Int(5 * CueSynthesizer.sampleRate))
    }

    @Test(arguments: CueSound.flowing)
    func flowingSoundsSwellWhileBreathingInAndRecedeWhileBreathingOut(sound: CueSound) {
        let inhale = CueSynthesizer.render(.init(sound: sound, kind: .inhale, seconds: 6)).left
        let exhale = CueSynthesizer.render(.init(sound: sound, kind: .exhale, seconds: 6)).left
        let quarter = inhale.count / 4
        // Skip the onset accent and the fades; compare the body of the sound.
        let early = quarter...(2 * quarter - 1)
        let late = (2 * quarter)...(3 * quarter + quarter / 2)
        #expect(rms(inhale[late]) > rms(inhale[early]))
        #expect(rms(exhale[late]) < rms(exhale[early]))
    }

    @Test func struckSoundsDoNotDependOnThePhaseLength() {
        for sound in CueSound.struck {
            #expect(CueSynthesizer.Request(sound: sound, kind: .inhale, seconds: 2)
                == CueSynthesizer.Request(sound: sound, kind: .inhale, seconds: 9))
        }
        #expect(CueSynthesizer.Request(sound: .ocean, kind: .inhale, seconds: 2)
            != CueSynthesizer.Request(sound: .ocean, kind: .inhale, seconds: 9))
    }

    @Test func rendersTheSameEveryTime() {
        let request = CueSynthesizer.Request(sound: .chimes, kind: .exhale, variant: 2)
        #expect(CueSynthesizer.render(request) == CueSynthesizer.render(request))
    }

    @Test func soundsAreGroupedOnce() {
        #expect(Set(CueSound.struck + CueSound.flowing) == Set(CueSound.allCases))
        #expect(CueSound.struck.count + CueSound.flowing.count == CueSound.allCases.count)
    }

    @Test func volumeFollowsADecibelScale() {
        #expect(CueSynthesizer.gain(forVolume: 0) == 0)
        #expect(abs(CueSynthesizer.gain(forVolume: 1) - 1) < 0.0001)
        // Halfway is 15 dB down.
        #expect(abs(CueSynthesizer.gain(forVolume: 0.5) - 0.1778) < 0.001)
        #expect(CueSynthesizer.gain(forVolume: 0.3) < CueSynthesizer.gain(forVolume: 0.6))
        #expect(CueSynthesizer.gain(forVolume: 2) == CueSynthesizer.gain(forVolume: 1))
    }
}

struct CueSettingsTests {
    @Test func olderSettingsGetTheDefaultSoundAndVolume() throws {
        let json = Data(#"{"soundEnabled": true}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: json)
        #expect(settings.cueSound == .bowl)
        #expect(settings.cueVolume == 0.9)
    }

    @Test func anUnknownSoundFallsBackWithoutLosingOtherSettings() throws {
        let json = Data(#"{"cueSound": "harp", "cueVolume": 0.3, "hapticsEnabled": false}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: json)
        #expect(settings.cueSound == .bowl)
        #expect(settings.cueVolume == 0.3)
        #expect(!settings.hapticsEnabled)
    }

    @Test func volumeIsKeptInRange() throws {
        let json = Data(#"{"cueVolume": 4}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: json)
        #expect(settings.cueVolume == 1)
    }

    @Test func soundAndVolumeRoundTrip() throws {
        var settings = AppSettings()
        settings.cueSound = .wave
        settings.cueVolume = 0.55
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }
}

struct SessionCueTests {
    private final class RecordingCuePlayer: BreathingCuePlaying {
        var preloaded: [BreathPhase] = []
        var cued: [BreathPhase.Kind] = []
        var stops = 0

        func preload(_ phases: [BreathPhase]) { preloaded = phases }
        func cue(_ phase: BreathPhase) { cued.append(phase.kind) }
        func stop() { stops += 1 }
    }

    private final class Monitor: LiveHeartRateProviding {
        var isConnected = false
        var heartRate: Int?
        var hrv: HRV?
    }

    @Test func preloadsThePhasesAndSilencesCuesOnPauseAndEnd() async throws {
        var now = Date(timeIntervalSince1970: 1_000)
        var settings = AppSettings()
        settings.countdownEnabled = false
        let player = RecordingCuePlayer()
        let phases: [BreathPhase] = [.inhale(4), .exhale(4)]
        let session = BreathingSessionModel(
            technique: .testTechnique(phases: phases, duration: 60),
            monitor: Monitor(),
            settings: settings,
            source: .iPhone,
            cuePlayer: player,
            now: { now },
            onComplete: { _ in }
        )
        session.start()
        try await Task.sleep(for: .milliseconds(100))

        #expect(player.preloaded == phases)
        #expect(player.cued.first == .inhale)

        session.pause()
        #expect(player.stops == 1)

        session.resume()
        now += 20
        session.end()
        #expect(player.stops >= 2)
    }
}
