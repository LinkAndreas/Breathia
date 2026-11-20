import Foundation
import Testing
@testable import Breathia

/// Turning a large iPhone sideways rebuilds the session cover; the session must
/// carry on instead of starting over.
struct SessionKeeperTests {
    private final class Monitor: LiveHeartRateProviding {
        var isConnected = false
        var heartRate: Int?
        var hrv: HRV?
    }

    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    private func makeSession(clock: Clock) -> BreathingSessionModel {
        var settings = AppSettings()
        settings.countdownEnabled = false
        return BreathingSessionModel(
            technique: .testTechnique(phases: [.inhale(4), .exhale(4)], duration: 60),
            monitor: Monitor(),
            settings: settings,
            source: .iPhone,
            cuePlayer: SilentBreathingCuePlayer(),
            now: { clock.now },
            onComplete: { _ in }
        )
    }

    @Test func aRebuiltScreenGetsTheRunningSession() async throws {
        let clock = Clock()
        let keeper = SessionKeeper()
        var made = 0
        let make = { () -> BreathingSessionModel in
            made += 1
            return self.makeSession(clock: clock)
        }

        // The first screen starts the session.
        keeper.attach()
        let first = keeper.session(make: make)
        first.start()
        try await Task.sleep(for: .milliseconds(100))
        clock.now += 20

        // The layout changes: the new screen appears, the old one goes.
        keeper.attach()
        let second = keeper.session(make: make)
        keeper.detach()
        second.start()

        #expect(first === second)
        #expect(made == 1)
        #expect(second.stage == .running)
        try await Task.sleep(for: SessionKeeper.gracePeriod + .milliseconds(300))
        #expect(second.stage == .running)

        second.end()
        #expect(second.wasRecorded)
    }

    @Test func theOldScreenGoingFirstStillKeepsTheSession() async throws {
        let clock = Clock()
        let keeper = SessionKeeper()
        keeper.attach()
        let first = keeper.session { makeSession(clock: clock) }
        first.start()
        try await Task.sleep(for: .milliseconds(100))

        // The old screen disappears before the new one appears.
        keeper.detach()
        keeper.attach()
        let second = keeper.session { makeSession(clock: clock) }
        try await Task.sleep(for: SessionKeeper.gracePeriod + .milliseconds(300))

        #expect(first === second)
        #expect(second.stage == .running)
    }

    @Test func leavingEndsTheSessionAndTheNextOneIsNew() {
        let clock = Clock()
        let keeper = SessionKeeper()
        keeper.attach()
        let first = keeper.session { makeSession(clock: clock) }
        keeper.release()
        keeper.detach()

        keeper.attach()
        let next = keeper.session { makeSession(clock: clock) }
        #expect(first !== next)
    }

    @Test func aScreenThatNeverComesBackEndsTheSession() async throws {
        let clock = Clock()
        // A short grace period, so the test doesn't depend on how busy the machine is.
        let keeper = SessionKeeper(gracePeriod: .milliseconds(50))
        keeper.attach()
        let first = keeper.session { makeSession(clock: clock) }
        keeper.detach()
        #expect(keeper.isHoldingSession)

        // Other tests can keep the main actor busy, so wait for the release rather
        // than a fixed time.
        let deadline = ContinuousClock.now + .seconds(60)
        while keeper.isHoldingSession, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(!keeper.isHoldingSession)

        keeper.attach()
        let next = keeper.session { makeSession(clock: clock) }
        #expect(first !== next)
    }
}
