import Foundation
import OSLog

/// Adapts `BluetoothManager` to `HeartRateSource`, parsing raw characteristic
/// values into measurements.
final class BluetoothHeartRateSource: HeartRateSource {
    var onStatusChange: ((ConnectionStatus) -> Void)?
    var onMeasurement: ((HeartRateMeasurement) -> Void)?

    private let manager: BluetoothManager
    private let logger = Logger(subsystem: "Breathia", category: "Bluetooth")

    init(device: BluetoothDevice, service: BluetoothService) {
        manager = BluetoothManager(device: device, service: service)
        manager.delegate = self
    }

    var status: ConnectionStatus { manager.status }

    func requestPermission() { manager.requestPermission() }
    func startScan() { manager.startScan() }
    func connect(to id: UUID) { manager.connect(to: id) }
    func disconnect() { manager.disconnect() }
}

extension BluetoothHeartRateSource: BluetoothManagerDelegate {
    func manager(_ manager: BluetoothManager, didChangeStatus status: ConnectionStatus) {
        onStatusChange?(status)
    }

    func manager(_ manager: BluetoothManager, didReceive data: Data) {
        guard let measurement = MeasurementParser.parse(data) else {
            logger.error("Dropped a malformed heart-rate measurement (\(data.count) bytes)")
            return
        }
        onMeasurement?(measurement)
    }

    func manager(_ manager: BluetoothManager, didEncounter error: any Error) {
        logger.error("Bluetooth error: \(String(describing: error), privacy: .public)")
    }
}
