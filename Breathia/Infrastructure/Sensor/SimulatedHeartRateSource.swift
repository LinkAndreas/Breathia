// Previews, tests, and the Simulator, which has no Bluetooth radio; not part of the app on devices.
#if DEBUG || targetEnvironment(simulator)
import Foundation

/// A fake chest strap for previews and the Simulator. It walks through the same
/// permission → scan → connect → stream lifecycle as the real sensor and emits
/// heart-rate values with a breathing-like oscillation whose amplitude grows over
/// time, so the live biofeedback has something meaningful to show.
///
/// Like the real Bluetooth permission, the simulated one is asked for once: the
/// grant is remembered, so the permission screen doesn't come back on later launches.
final class SimulatedHeartRateSource: HeartRateSource {
    private static let permissionKey = "com.breathia.simulatedSensor.hasPermission"

    var onStatusChange: ((ConnectionStatus) -> Void)?
    var onMeasurement: ((HeartRateMeasurement) -> Void)?

    private(set) var status: ConnectionStatus {
        didSet { onStatusChange?(status) }
    }

    private let defaults: UserDefaults
    private let sensor = DiscoveredPeripheral(id: UUID(), name: "Polar H10 (Simulated)", rssi: -52)
    private var task: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.status = defaults.bool(forKey: Self.permissionKey) ? .idle : .needsPermission
    }

    /// Grants access after a moment, standing in for the system prompt.
    func requestPermission() {
        guard status == .needsPermission else { return }
        run {
            try await Task.sleep(for: .seconds(0.6))
            self.defaults.set(true, forKey: Self.permissionKey)
            self.status = .idle
        }
    }

    func startScan() {
        switch status {
        case .idle, .failed: break
        default: return
        }
        status = .scanning(found: [])
        run { [sensor] in
            try await Task.sleep(for: .seconds(1.2))
            self.status = .scanning(found: [sensor])
        }
    }

    func connect(to id: UUID) {
        guard case .scanning = status, id == sensor.id else { return }
        status = .connecting(name: sensor.name)
        run {
            try await Task.sleep(for: .seconds(1))
            self.status = .connected(isStreaming: true)
            try await self.stream()
        }
    }

    func disconnect() {
        guard status != .needsPermission, status != .denied else { return }
        task?.cancel()
        task = nil
        status = .idle
    }

    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        task?.cancel()
        task = Task { try? await operation() }
    }

    private func stream() async throws {
        var seconds = 0.0
        while true {
            try await Task.sleep(for: .seconds(1))
            seconds += 1

            let settling = min(8, seconds * 0.03)
            let amplitude = 3 + min(4, seconds / 60)
            let breathing = amplitude * sin(2 * .pi * seconds / 10)
            let heartRate = 70 - settling + breathing + Double.random(in: -0.8...0.8)
            let rrInterval = 60_000 / heartRate + Double.random(in: -6...6)

            let measurement = HeartRateMeasurement(
                heartRate: Int(heartRate.rounded()),
                rrIntervals: [rrInterval]
            )
            onMeasurement?(measurement)
        }
    }
}
#endif
