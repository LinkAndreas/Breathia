import CoreBluetooth

struct Connecting: CentralState {
    var status: ConnectionStatus { .connecting(name: peripheral.name) }
    var trackedPeripheral: CBPeripheral? { peripheral }

    let peripheral: CBPeripheral
    let environment: CentralEnvironment

    func enter() {
        environment.manager.connect(peripheral)
    }

    func disconnect() {
        environment.manager.cancelPeripheralConnection(peripheral)
        environment.handleEvent(.disconnected)
    }

    func didConnect(_ peripheral: CBPeripheral) {
        guard self.peripheral == peripheral else { return }

        environment.handleEvent(.linkEstablished(peripheral))
    }

    func didFailToConnect(_ peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral == peripheral else { return }

        environment.handleEvent(.linkFailed(peripheral, error))
    }
}
