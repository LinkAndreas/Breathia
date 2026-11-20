import Foundation
import Testing
@testable import Breathia

struct CueSynthesizerTests {
    private static let kinds: [BreathPhase.Kind] = [.inhale, .hold, .exhale]

    private func peak(_ samples: [Float]) -> Float {
        samples.reduce(0) { max($0, abs($1)) }
    }

    private func rms(_ samples: ArraySlice<Float>) -> Float {
        (samples.reduce(0) { $0 + $1 * $1 } / Float(max(1, samples.count))).squareRoot()
    }

    @Test(arguments: CueSound.allCases)
    func everyCueIsAudibleAndNeverClips(sound: CueSound) {
        for kind in Self.kinds {
            let samples = CueSynthesizer.render(.init(sound: sound, kind: kind, seconds: 4))
            #expect(!samples.isEmpty)
            let allFinite = samples.allSatisfy { $0.isFinite }
            #expect(allFinite)
            #expect(peak(samples) <= CueSynthesizer.peakLevel + 0.0001)
            // Far louder than the old chime, which peaked around 0.11.
            #expect(peak(samples) >= 0.5)
        }
    }

    /// No click: every cue fades in from silence and out to silence.
    @Test(arguments: CueSound.allCases)
    func cuesStartAndEndInSilence(sound: CueSound) {
        for kind in Self.kinds {
            let samples = CueSynthesizer.render(.init(sound: sound, kind: kind, seconds: 4))
            #expect(abs(samples.first ?? 1) < 0.01)
            #expect(abs(samples.last ?? 1) < 0.01)
        }
    }

    @Test(arguments: CueSound.allCases)
    func holdIsQuieterThanBreathing(sound: CueSound) {
        let inhale = CueSynthesizer.render(.init(sound: sound, kind: .inhale, seconds: 4))
        let hold = CueSynthesizer.render(.init(sound: sound, kind: .hold, seconds: 4))
        #expect(peak(hold) < peak(inhale))
    }

    @Test func notesRiseForInhaleAndFallForExhale() {
        #expect(CueSynthesizer.frequency(of: .inhale) > CueSynthesizer.frequency(of: .hold))
        #expect(CueSynthesizer.frequency(of: .hold) > CueSynthesizer.frequency(of: .exhale))
        // High enough to carry on small speakers.
        #expect(CueSynthesizer.frequency(of: .exhale) >= 300)
    }

    @Test func waveLastsTheWholePhase() {
        let samples = CueSynthesizer.render(.init(sound: .wave, kind: .inhale, seconds: 5))
        #expect(samples.count == Int(5 * CueSynthesizer.sampleRate))
    }

    @Test func waveSwellsWhileBreathingInAndRecedesWhileBreathingOut() {
        let inhale = CueSynthesizer.render(.init(sound: .wave, kind: .inhale, seconds: 6))
        let exhale = CueSynthesizer.render(.init(sound: .wave, kind: .exhale, seconds: 6))
        let quarter = inhale.count / 4
        // Skip the onset accent and the fades; compare the body of the tone.
        let early = quarter...(2 * quarter - 1)
        let late = (2 * quarter)...(3 * quarter + quarter / 2)
        #expect(rms(inhale[late]) > rms(inhale[early]))
        #expect(rms(exhale[late]) < rms(exhale[early]))
    }

    @Test func struckSoundsDoNotDependOnThePhaseLength() {
        let short = CueSynthesizer.Request(sound: .bowl, kind: .inhale, seconds: 2)
        let long = CueSynthesizer.Request(sound: .bowl, kind: .inhale, seconds: 9)
        #expect(short == long)
        #expect(CueSynthesizer.Request(sound: .wave, kind: .inhale, seconds: 2)
            != CueSynthesizer.Request(sound: .wave, kind: .inhale, seconds: 9))
    }

    @Test func rendersTheSameEveryTime() {
        let request = CueSynthesizer.Request(sound: .bell, kind: .exhale)
        #expect(CueSynthesizer.render(request) == CueSynthesizer.render(request))
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
