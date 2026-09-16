import CoreBluetooth

/// What a stage 2 state reports after handling an event; `PeripheralSession`
/// decides which state follows. Failures aren't events — handlers throw instead.
enum SessionEvent {
    case serviceFound(CBService)
    case characteristicsFound([CBCharacteristic])
    case received(value: Result<Data, Error>, characteristic: CBCharacteristic)
}
