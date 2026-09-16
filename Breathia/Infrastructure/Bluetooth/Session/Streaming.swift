import CoreBluetooth

struct Streaming: SessionState {
    let characteristics: [CBCharacteristic]
    let environment: SessionEnvironment

    var isStreaming: Bool { true }

    func enter() {
        for characteristic in characteristics {
            environment.peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func exit() {
        // Only unsubscribe on a live link; after a drop there's nothing to tell.
        guard environment.peripheral.state == .connected else { return }
        for characteristic in characteristics {
            environment.peripheral.setNotifyValue(false, for: characteristic)
        }
    }

    func didUpdateNotificationState(for characteristic: CBCharacteristic, error: Error?) throws {
        guard characteristics.contains(characteristic) else { return }
        if let error { throw error } // never subscribed — nothing will ever arrive
    }

    func didUpdateValue(for characteristic: CBCharacteristic, error: Error?) {
        guard characteristics.contains(characteristic) else { return }

        if let error {
            let event: SessionEvent = .received(value: .failure(error), characteristic: characteristic)
            environment.handleEvent(event) // a single bad notification doesn't end the session
        } else if let data = characteristic.value {
            let event: SessionEvent = .received(value: .success(data), characteristic: characteristic)
            environment.handleEvent(event)
        }
    }
}
