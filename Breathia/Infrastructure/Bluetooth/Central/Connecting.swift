import CoreBluetooth

/// Waits for the link to the picked sensor. A class, because it owns the timeout
/// task: CoreBluetooth never gives up on a connection by itself, so a sensor that
/// went away before the link came up would leave the app connecting forever.
final class Connecting: CentralState {
    private static let timeout: Duration = .seconds(15)

    var status: ConnectionStatus { .connecting(name: name) }
    var trackedPeripheral: CBPeripheral? { peripheral }
    private var timeoutTask: Task<Void, Never>?

    let peripheral: CBPeripheral
    /// The name the sensor was listed with — some sensors only advertise it.
    let name: String?
    let environment: CentralEnvironment

    init(peripheral: CBPeripheral, name: String?, environment: CentralEnvironment) {
        self.peripheral = peripheral
        self.name = name
        self.environment = environment
    }

    func enter() {
        environment.manager.connect(peripheral)
        let manager = environment.manager
        let peripheral = peripheral
        let handleEvent = environment.handleEvent
        timeoutTask = Task {
            try? await Task.sleep(for: Self.timeout)
            guard !Task.isCancelled else { return } // the link came up, or the user cancelled

            manager.cancelPeripheralConnection(peripheral)
            handleEvent(.linkFailed(peripheral, BluetoothError.connectionTimedOut))
        }
    }

    func exit() {
        timeoutTask?.cancel()
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
