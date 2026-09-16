import CoreBluetooth

/// Retries the connection with exponential backoff. A class, because it owns the
/// retry task: `enter` schedules it, `exit` cancels it — whichever way the state is left.
final class Reconnecting: CentralState {
    private static let maxAttempts = 5
    private static let maxDelay: Duration = .seconds(30)

    var status: ConnectionStatus { .reconnecting(attempt: attempt) }
    var trackedPeripheral: CBPeripheral? { peripheral }
    private var retryTask: Task<Void, Never>?

    let peripheral: CBPeripheral
    let attempt: Int
    let environment: CentralEnvironment

    init(peripheral: CBPeripheral, attempt: Int, environment: CentralEnvironment) {
        self.peripheral = peripheral
        self.attempt = attempt
        self.environment = environment
    }

    func enter() {
        let delay = Self.backoffDelay(for: attempt)
        let manager = environment.manager
        let peripheral = peripheral
        retryTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return } // someone else already moved the state on

            manager.connect(peripheral)
            // Stay here — didConnect / didFailToConnect resolve it below.
        }
    }

    func exit() {
        retryTask?.cancel()
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

        nextAttempt()
    }

    func didDisconnect(_ peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral == peripheral else { return }

        nextAttempt()
    }

    private func nextAttempt() {
        if attempt < Self.maxAttempts {
            environment.handleEvent(.reconnectNeeded(peripheral, attempt: attempt + 1))
        } else {
            environment.handleEvent(.linkFailed(peripheral, BluetoothError.reconnectAttemptsExhausted))
        }
    }

    private static func backoffDelay(for attempt: Int) -> Duration {
        let exponential = min(pow(2.0, Double(attempt - 1)), Double(maxDelay.components.seconds))
        let jitter = Double.random(in: 0...0.3) * exponential
        return .seconds(exponential + jitter)
    }
}
