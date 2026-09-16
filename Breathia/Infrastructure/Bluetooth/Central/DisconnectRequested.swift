import CoreBluetooth

struct DisconnectRequested: CentralState {
    let peripheral: CBPeripheral
    let environment: CentralEnvironment

    var status: ConnectionStatus { .disconnecting }
    var trackedPeripheral: CBPeripheral? { peripheral }

    func didDisconnect(_ peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral == peripheral else { return }

        environment.handleEvent(.disconnected) // graceful path — the user asked for this
    }
}
