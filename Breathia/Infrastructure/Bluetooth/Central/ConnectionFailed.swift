import CoreBluetooth

struct ConnectionFailed: CentralState {
    var status: ConnectionStatus { .failed }

    let peripheral: CBPeripheral
    let error: Error?
    let environment: CentralEnvironment

    func startScan() {
        environment.handleEvent(.scanRequested)
    }

    func connect(to id: UUID) {
        if id == peripheral.identifier {
            environment.handleEvent(.peripheralSelected(peripheral))
        }
    }

    func disconnect() {
        environment.handleEvent(.disconnected)
    }
}
