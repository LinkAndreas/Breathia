import CoreBluetooth

/// Bluetooth can't be used: access was denied, or the radio is off, resetting, or
/// unsupported. Waits for the system to report it's powered on again.
struct Unavailable: CentralState {
    var status: ConnectionStatus {
        reason == .unauthorized ? .denied : .unavailable
    }

    let reason: CBManagerState
    let environment: CentralEnvironment

    func didUpdateState(_ managerState: CBManagerState) {
        let event: CentralEvent = managerState == .poweredOn ? .bluetoothReady : .bluetoothUnavailable(managerState)
        environment.handleEvent(event)
    }
}
