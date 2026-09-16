import CoreBluetooth

struct DiscoveringCharacteristics: SessionState {
    let service: CBService
    let environment: SessionEnvironment

    func enter() {
        let uuids = environment.service.characteristicUUIDs
        environment.peripheral.discoverCharacteristics(uuids, for: service)
    }

    func didDiscoverCharacteristics(for service: CBService, error: Error?) throws {
        guard service == self.service else { return }
        if let error { throw error }

        let characteristics = (service.characteristics?.filter { characteristic in
            environment.service.characteristicUUIDs.contains(characteristic.uuid)
        }) ?? []

        guard !characteristics.isEmpty else {
            throw BluetoothError.characteristicNotFound
        }

        environment.handleEvent(.characteristicsFound(characteristics))
    }
}
