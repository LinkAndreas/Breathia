import CoreBluetooth

/// Everything a stage 1 state needs to act on CoreBluetooth.
struct CentralEnvironment {
    let manager: CBCentralManager
    let service: BluetoothService
    let preferredDevice: BluetoothDevice
    let handleEvent: (CentralEvent) -> Void
}

/// A state of stage 1 — discovering and connecting to a peripheral.
///
/// Each conforming type implements only the events it reacts to. A handler reports
/// what happened as a `CentralEvent` (or nothing, to stay in the current state); it
/// never names another state — `BluetoothManager` maps events to states. On every
/// transition the manager calls `exit` on the old state and `enter` on the new one,
/// so setting up and tearing down a state's resources (scan, retry task, session)
/// lives in those hooks instead of in every handler.
///
/// Peripheral-level events (services, characteristics, values) never reach these
/// states — they belong to `PeripheralSession` (stage 2), which `Connected` owns.
protocol CentralState {
    var environment: CentralEnvironment { get }

    var status: ConnectionStatus { get }
    /// The peripheral this state is waiting on. The manager drops connect/disconnect
    /// events for any other peripheral before dispatching them.
    var trackedPeripheral: CBPeripheral? { get }

    func enter()
    func exit()

    // User intents
    func startScan()
    func connect(to id: UUID)
    func disconnect()

    // CBCentralManager events
    func didUpdateState(_ managerState: CBManagerState)
    func didDiscover(_ peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int)
    func didConnect(_ peripheral: CBPeripheral)
    func didFailToConnect(_ peripheral: CBPeripheral, error: Error?)
    func didDisconnect(_ peripheral: CBPeripheral, error: Error?)

    // Stage 2 feedback
    func sessionDidFail(_ error: Error)
}

extension CentralState {
    var trackedPeripheral: CBPeripheral? { nil }

    func enter() {}
    func exit() {}

    func startScan() {}
    func connect(to id: UUID) {}
    func disconnect() {}

    func didUpdateState(_ managerState: CBManagerState) {
        // Global interrupt: powered off / unauthorized / unsupported / resetting forces
        // every state into `Unavailable`; its `exit` hook releases whatever it held.
        if managerState != .poweredOn {
            environment.handleEvent(.bluetoothUnavailable(managerState))
        }
    }
    func didDiscover(_ peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int) {}
    func didConnect(_ peripheral: CBPeripheral) {}
    func didFailToConnect(_ peripheral: CBPeripheral, error: Error?) {}
    func didDisconnect(_ peripheral: CBPeripheral, error: Error?) {}

    func sessionDidFail(_ error: Error) {}
}
