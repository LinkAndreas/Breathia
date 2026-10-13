import CoreBluetooth

/// Stage 1: owns the `CBCentralManager` and drives the `CentralState` machine
/// (scan → pick → connect → reconnect). Once connected, the `Connected` state owns
/// a `PeripheralSession` (stage 2), which reports values and failures back here.
///
/// Creating a `CBCentralManager` is what shows the Bluetooth permission prompt, so
/// while access is undecided the manager isn't created until `requestPermission()`
/// — when the user sets out to connect a sensor, not at app launch.
final class BluetoothManager: NSObject {
    weak var delegate: BluetoothManagerDelegate?
    private(set) var status: ConnectionStatus

    private let device: BluetoothDevice
    private let service: BluetoothService
    private var manager: CBCentralManager?
    /// `nil` until the central manager exists.
    private var state: CentralState?

    private var environment: CentralEnvironment {
        CentralEnvironment(
            // States only exist once `activate()` has created the manager.
            manager: manager!,
            service: service,
            preferredDevice: device,
            handleEvent: handleEvent
        )
    }

    init(device: BluetoothDevice, service: BluetoothService) {
        self.device = device
        self.service = service
        self.status = Self.statusBeforeActivation
        super.init()

        // Once the user has decided, creating the manager shows no prompt, so start
        // right away and keep the sensor ready as before.
        if CBManager.authorization != .notDetermined {
            activate()
        }
    }

    func requestPermission() {
        activate()
    }

    func startScan() {
        state?.startScan()
    }

    func connect(to id: UUID) {
        state?.connect(to: id)
    }

    func disconnect() {
        state?.disconnect()
    }

    private func activate() {
        guard manager == nil else { return }
        manager = CBCentralManager(delegate: self, queue: nil)
        state = NotDetermined(environment: environment)
        publishStatusIfChanged()
    }

    /// What to show before the central manager exists, read without prompting.
    private static var statusBeforeActivation: ConnectionStatus {
        switch CBManager.authorization {
        case .notDetermined: .needsPermission
        case .denied, .restricted: .denied
        default: .unavailable
        }
    }

    private func transition(to nextState: CentralState) {
        state?.exit()
        state = nextState
        nextState.enter()
        publishStatusIfChanged()
    }

    private func handleEvent(_ event: CentralEvent) {
        switch event {
        case .bluetoothReady, .disconnected:
            transition(to: Idle(environment: environment))
        case let .bluetoothUnavailable(reason):
            transition(to: Unavailable(reason: reason, environment: environment))
        case .scanRequested:
            transition(to: Scanning(environment: environment))
        case .peripheralFound:
            publishStatusIfChanged()
        case let .peripheralSelected(peripheral, name):
            transition(to: Connecting(peripheral: peripheral, name: name, environment: environment))
        case let .linkEstablished(peripheral):
            // Hand-off to stage 2.
            transition(to: Connected(environment: environment, session: makeSession(for: peripheral)))
        case let .linkFailed(peripheral, error):
            transition(to: ConnectionFailed(peripheral: peripheral, error: error, environment: environment))
        case let .reconnectNeeded(peripheral, attempt):
            transition(to: Reconnecting(peripheral: peripheral, attempt: attempt, environment: environment))
        case let .disconnectRequested(peripheral):
            transition(to: DisconnectRequested(peripheral: peripheral, environment: environment))
        case let .sessionFailed(peripheral, error):
            transition(to: ConnectionLost(peripheral: peripheral, error: error, environment: environment))
        }
    }

    private func publishStatusIfChanged() {
        let newStatus = state?.status ?? Self.statusBeforeActivation
        guard newStatus != status else { return }

        status = newStatus
        delegate?.manager(self, didChangeStatus: newStatus)
    }

    /// Connect and disconnect events only concern the peripheral the current state
    /// waits on. A late event from another one — e.g. a sensor that was just
    /// cancelled — must not drive the state machine (it would reconnect to it).
    private func isTracked(_ peripheral: CBPeripheral) -> Bool {
        state?.trackedPeripheral == peripheral
    }

    private func makeSession(for peripheral: CBPeripheral) -> PeripheralSession {
        let session = PeripheralSession(peripheral: peripheral, service: service)
        session.onValue = { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(data):
                delegate?.manager(self, didReceive: data)
            case let .failure(error):
                delegate?.manager(self, didEncounter: error)
            }
        }
        session.onStateChange = { [weak self] in
            self?.publishStatusIfChanged()
        }
        session.onFailure = { [weak self] error in
            guard let self else { return }
            delegate?.manager(self, didEncounter: error)
            state?.sessionDidFail(error)
        }
        return session
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state?.didUpdateState(central.state)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        state?.didDiscover(peripheral, advertisementData: advertisementData, rssi: RSSI.intValue)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard isTracked(peripheral) else { return }
        state?.didConnect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard isTracked(peripheral) else { return }
        state?.didFailToConnect(peripheral, error: error)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard isTracked(peripheral) else { return }
        state?.didDisconnect(peripheral, error: error)
    }
}
