import CoreBluetooth

struct Idle: CentralState {
    let environment: CentralEnvironment
    var status: ConnectionStatus { .idle }

    func startScan() {
        environment.handleEvent(.scanRequested)
    }
}
