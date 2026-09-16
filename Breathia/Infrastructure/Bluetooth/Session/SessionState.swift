import CoreBluetooth

/// Everything a stage 2 state needs to act on the connected peripheral.
struct SessionEnvironment {
    let peripheral: CBPeripheral
    let service: BluetoothService
    var handleEvent: (SessionEvent) -> Void
}

/// A state of stage 2 — turning a connected peripheral into a stream of values.
///
/// Same rules as `CentralState`: handlers report a `SessionEvent` (or nothing, to
/// stay), `PeripheralSession` picks the next state, and `enter`/`exit` run on every
/// transition.
/// Throwing ends the session; `PeripheralSession` reports the error to stage 1,
/// which drops the link.
protocol SessionState {
    var environment: SessionEnvironment { get }

    var isStreaming: Bool { get }

    func enter()
    func exit()

    func didDiscoverServices(error: Error?) throws
    func didDiscoverCharacteristics(for service: CBService, error: Error?) throws
    func didUpdateNotificationState(for characteristic: CBCharacteristic, error: Error?) throws
    func didUpdateValue(for characteristic: CBCharacteristic, error: Error?)
}

extension SessionState {
    var isStreaming: Bool { false }

    func enter() {}
    func exit() {}

    func didDiscoverServices(error: Error?) throws {}
    func didDiscoverCharacteristics(for service: CBService, error: Error?) throws {}
    func didUpdateNotificationState(for characteristic: CBCharacteristic, error: Error?) throws {}
    func didUpdateValue(for characteristic: CBCharacteristic, error: Error?) {}
}
