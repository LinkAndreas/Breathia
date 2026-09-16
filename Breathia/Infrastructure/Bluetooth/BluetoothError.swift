import Foundation

enum BluetoothError: Error {
    case reconnectAttemptsExhausted
    case serviceNotFound
    case characteristicNotFound
}
