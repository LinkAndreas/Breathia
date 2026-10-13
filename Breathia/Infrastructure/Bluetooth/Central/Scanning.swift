import CoreBluetooth

/// Collects peripherals advertising the service until the user picks one.
/// A class, because the list changes while the state stays the same.
final class Scanning: CentralState {
    var status: ConnectionStatus { .scanning(found: found) }

    private var found: [DiscoveredPeripheral] = []
    private var peripherals: [UUID: CBPeripheral] = [:]

    let environment: CentralEnvironment

    init(environment: CentralEnvironment) {
        self.environment = environment
    }

    func enter() {
        let uuids = [environment.service.uuid]
        environment.manager.scanForPeripherals(
            withServices: uuids,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        // A sensor already connected to the system — through another app, say —
        // stops advertising, so the scan alone would never find it.
        for peripheral in environment.manager.retrieveConnectedPeripherals(withServices: uuids) {
            didDiscover(peripheral, advertisementData: [:], rssi: 0)
        }
    }

    func exit() {
        // Leaving because Bluetooth went away — the scan is already gone.
        guard environment.manager.state == .poweredOn else { return }
        environment.manager.stopScan()
    }

    func disconnect() {
        environment.handleEvent(.disconnected)
    }

    func connect(to id: UUID) {
        guard let peripheral = peripherals[id] else { return }

        let name = found.first { $0.id == id }?.name
        environment.handleEvent(.peripheralSelected(peripheral, name: name))
    }

    func didDiscover(_ peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int) {
        // `nil` when the peripheral advertises no name; the UI shows a localized fallback.
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let entry = DiscoveredPeripheral(id: peripheral.identifier, name: name, rssi: rssi)
        peripherals[peripheral.identifier] = peripheral

        if let index = found.firstIndex(where: { $0.id == entry.id }) {
            found[index] = entry
        } else {
            found.append(entry)
            // Keep the device the app is designed around at the top of the list.
            let preferred = environment.preferredDevice.name
            func isPreferred(_ sensor: DiscoveredPeripheral) -> Bool { sensor.name?.hasPrefix(preferred) == true }
            found.sort { isPreferred($0) && !isPreferred($1) }
        }

        environment.handleEvent(.peripheralFound(peripheral))
    }
}
