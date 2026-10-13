import Foundation
import Observation

/// The app-wide view of the heart-rate sensor: Bluetooth access, connection
/// status, the latest heart rate, and HRV over a rolling window of RR intervals.
@Observable
final class HeartRateMonitor: LiveHeartRateProviding {
    private(set) var status: ConnectionStatus
    private(set) var heartRate: Int?
    private(set) var hrv: HRV?
    /// The name of the sensor being connected to, or the last one connected;
    /// until then, or for a sensor that advertises no name, a generic one.
    private(set) var sensorName: String
    /// `true` while the system's Bluetooth permission prompt is up.
    private(set) var isRequestingPermission = false

    @ObservationIgnored private let source: HeartRateSource
    @ObservationIgnored private var hrvCalculator = HRVCalculator()
    /// Set when access is requested, so searching starts as soon as it's granted.
    @ObservationIgnored private var scansWhenAllowed = false

    init(source: HeartRateSource) {
        self.source = source
        self.status = source.status
        self.sensorName = Self.genericSensorName
        source.onStatusChange = { [weak self] status in self?.apply(status) }
        source.onMeasurement = { [weak self] measurement in self?.ingest(measurement) }
    }

    private static var genericSensorName: String {
        String(localized: "sensor.heartRateSensor")
    }

    var isConnected: Bool {
        if case .connected = status { true } else { false }
    }

    var isScanning: Bool {
        if case .scanning = status { true } else { false }
    }

    var discoveredSensors: [DiscoveredPeripheral] {
        if case let .scanning(found) = status { found } else { [] }
    }

    /// Shows the system's Bluetooth permission prompt, then starts searching for
    /// sensors once access is granted. Call it only after telling the user why.
    func requestPermission() {
        guard status == .needsPermission, !isRequestingPermission else { return }
        isRequestingPermission = true
        scansWhenAllowed = true
        source.requestPermission()
    }

    func startScan() {
        source.startScan()
    }

    /// Stops an in-progress scan; does nothing in any other state, so a connection
    /// that was just picked isn't cancelled by a sheet dismissing behind it.
    func stopScan() {
        guard isScanning else { return }
        source.disconnect()
    }

    func connect(to sensor: DiscoveredPeripheral) {
        source.connect(to: sensor.id)
    }

    func disconnect() {
        source.disconnect()
    }

    private func apply(_ status: ConnectionStatus) {
        self.status = status
        if status != .needsPermission {
            isRequestingPermission = false
        }
        if status == .idle, scansWhenAllowed {
            scansWhenAllowed = false
            source.startScan()
        } else if status == .denied {
            scansWhenAllowed = false
        }
        if case let .connecting(name) = status {
            sensorName = name ?? Self.genericSensorName
        }
        if !isConnected {
            heartRate = nil
            hrv = nil
            hrvCalculator.reset()
        }
    }

    /// A reading without skin contact is dropped, so sessions never record it — the
    /// heart rate and HRV show as unknown until the sensor sits right again.
    private func ingest(_ measurement: HeartRateMeasurement) {
        guard measurement.isValid else {
            heartRate = nil
            hrv = nil
            return
        }
        heartRate = measurement.heartRate
        if let value = hrvCalculator.calculate(from: measurement.rrIntervals) {
            hrv = value
        }
    }
}
