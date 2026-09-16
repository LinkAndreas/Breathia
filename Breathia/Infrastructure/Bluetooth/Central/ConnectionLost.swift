import CoreBluetooth

/// The session failed and the link is being torn down; reconnects once it's gone.
struct ConnectionLost: CentralState {
    let peripheral: CBPeripheral
    let error: Error
    let environment: CentralEnvironment

    var status: ConnectionStatus { .disconnecting }
    var trackedPeripheral: CBPeripheral? { peripheral }

    func disconnect() {
        environment.handleEvent(.disconnectRequested(peripheral)) // already cancelling — just don't reconnect
    }

    func didDisconnect(_ peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral == peripheral else { return }

        environment.handleEvent(.reconnectNeeded(peripheral, attempt: 1))
    }
}
