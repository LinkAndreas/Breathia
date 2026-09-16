import CoreBluetooth

struct DiscoveringServices: SessionState {
    let environment: SessionEnvironment

    func enter() {
        let uuids = [environment.service.uuid]
        environment.peripheral.discoverServices(uuids)
    }

    func didDiscoverServices(error: Error?) throws {
        if let error { throw error }

        guard let service = environment.peripheral.services?.first(where: { $0.uuid == environment.service.uuid }) else {
            throw BluetoothError.serviceNotFound
        }

        environment.handleEvent(.serviceFound(service))
    }
}
