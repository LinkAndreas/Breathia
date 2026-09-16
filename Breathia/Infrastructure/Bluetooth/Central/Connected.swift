import CoreBluetooth

/// The link is up. Owns the stage 2 `PeripheralSession` for exactly as long as
/// this state is active: `enter` starts it, `exit` tears it down.
struct Connected: CentralState {
    let environment: CentralEnvironment
    var status: ConnectionStatus { .connected(isStreaming: session.isStreaming) }
    var trackedPeripheral: CBPeripheral? { session.peripheral }

    let session: PeripheralSession

    func enter() {
        session.start()
    }

    func exit() {
        session.invalidate()
    }

    func disconnect() {
        environment.manager.cancelPeripheralConnection(session.peripheral)
        environment.handleEvent(.disconnectRequested(session.peripheral))
    }

    func didDisconnect(_ peripheral: CBPeripheral, error: Error?) {
        environment.handleEvent(.reconnectNeeded(peripheral, attempt: 1))
    }

    func sessionDidFail(_ error: Error) {
        // A link that can't deliver measurements is useless — drop it and let the
        // reconnect path start over with a fresh session.
        environment.manager.cancelPeripheralConnection(session.peripheral)
        environment.handleEvent(.sessionFailed(session.peripheral, error))
    }
}
