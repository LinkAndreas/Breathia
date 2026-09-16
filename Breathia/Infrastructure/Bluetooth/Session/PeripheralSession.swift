import CoreBluetooth

/// Stage 2: drives a connected peripheral from service discovery to streaming.
///
/// Created by stage 1 on `didConnect` and owned by the `Connected` state. It is the
/// peripheral's delegate, so peripheral events never reach the stage 1 states.
final class PeripheralSession: NSObject {
    private var environment: SessionEnvironment {
        SessionEnvironment(
            peripheral: peripheral,
            service: service,
            // Weak: the states hold the environment, and the session holds the states.
            handleEvent: { [weak self] event in self?.handleEvent(event) }
        )
    }

    let peripheral: CBPeripheral

    var onValue: ((Result<Data, Error>) -> Void)?
    var onStateChange: (() -> Void)?
    var onFailure: ((Error) -> Void)?

    private let service: BluetoothService
    private lazy var state: SessionState = DiscoveringServices(environment: environment)
    private var isActive = false

    var isStreaming: Bool { state.isStreaming }

    init(peripheral: CBPeripheral, service: BluetoothService) {
        self.peripheral = peripheral
        self.service = service
        super.init()
    }

    func start() {
        guard !isActive else { return }
        isActive = true
        peripheral.delegate = self
        state.enter()
    }

    func invalidate() {
        guard isActive else { return }
        isActive = false
        state.exit()
        peripheral.delegate = nil
    }

    private func transition(to nextState: SessionState) {
        guard isActive else { return }

        state.exit()
        state = nextState
        nextState.enter()
        onStateChange?()
    }

    private func handleEvent(_ event: SessionEvent) {
        switch event {
        case let .serviceFound(service):
            transition(
                to: DiscoveringCharacteristics(
                    service: service,
                    environment: environment
                )
            )
        case let .characteristicsFound(characteristics):
            transition(
                to: Streaming(
                    characteristics: characteristics,
                    environment: environment
                )
            )
        case let .received(value, _):
            onValue?(value)
        }
    }

    private func fail(with error: Error) {
        invalidate()
        onFailure?(error)
    }
}

extension PeripheralSession: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        do {
            try state.didDiscoverServices(error: error)
        } catch {
            fail(with: error)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        do {
            try state.didDiscoverCharacteristics(for: service, error: error)
        } catch {
            fail(with: error)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        do {
            try state.didUpdateNotificationState(for: characteristic, error: error)
        } catch {
            fail(with: error)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        state.didUpdateValue(for: characteristic, error: error)
    }
}
