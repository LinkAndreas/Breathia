import Foundation

enum BluetoothError: Error {
    case reconnectAttemptsExhausted
    case connectionTimedOut
    case serviceNotFound
    case characteristicNotFound
}
