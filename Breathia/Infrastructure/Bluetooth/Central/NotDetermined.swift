import CoreBluetooth

/// The central manager was just created and hasn't reported its state yet — for
/// a first-time user, that's while the Bluetooth permission prompt is up.
struct NotDetermined: CentralState {
    let environment: CentralEnvironment
    var status: ConnectionStatus {
        CBManager.authorization == .notDetermined ? .needsPermission : .unavailable
    }

    func didUpdateState(_ managerState: CBManagerState) {
        let event: CentralEvent = managerState == .poweredOn ? .bluetoothReady : .bluetoothUnavailable(managerState)
        environment.handleEvent(event)
    }
}
