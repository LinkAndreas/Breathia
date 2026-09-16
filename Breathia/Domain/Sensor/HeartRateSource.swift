import Foundation

/// Anything that can find, connect to, and stream from a heart-rate sensor.
/// `HeartRateMonitor` depends only on this, so the Bluetooth stack can be swapped
/// for a simulated strap in previews and in the Simulator.
protocol HeartRateSource: AnyObject {
    var status: ConnectionStatus { get }
    var onStatusChange: ((ConnectionStatus) -> Void)? { get set }
    var onMeasurement: ((HeartRateMeasurement) -> Void)? { get set }

    /// Asks for access to the sensor's radio (the system Bluetooth prompt) when
    /// `status` is `.needsPermission`; the answer arrives as a status change.
    func requestPermission()
    func startScan()
    func connect(to id: UUID)
    func disconnect()
}
