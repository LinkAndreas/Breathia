import CoreBluetooth

/// What a stage 1 state reports after handling an event. States only describe what
/// happened; `BluetoothManager` decides which state follows.
enum CentralEvent {
    case bluetoothReady
    case bluetoothUnavailable(CBManagerState)
    case scanRequested
    case peripheralFound(CBPeripheral)
    case peripheralSelected(CBPeripheral, name: String?)
    case linkEstablished(CBPeripheral)
    case linkFailed(CBPeripheral, Error?)
    case reconnectNeeded(CBPeripheral, attempt: Int)
    case disconnectRequested(CBPeripheral)
    case sessionFailed(CBPeripheral, Error)
    case disconnected
}
