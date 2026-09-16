import Foundation

/// A peripheral found while scanning, detached from CoreBluetooth so the UI
/// never holds on to a `CBPeripheral`.
struct DiscoveredPeripheral: Identifiable, Equatable {
    let id: UUID
    /// The advertised name; `nil` when the peripheral didn't send one.
    let name: String?
    let rssi: Int
}

/// A UI-facing snapshot of the connection lifecycle. Every `CentralState` maps
/// itself onto one of these; the manager publishes it whenever it changes.
enum ConnectionStatus: Equatable {
    /// Bluetooth access hasn't been asked for yet. Asking shows the system prompt,
    /// so it waits until the user sets out to connect a sensor.
    case needsPermission
    /// The user denied Bluetooth access, or it's restricted on this device.
    case denied
    /// Bluetooth is off, resetting, or not supported.
    case unavailable
    case idle
    case scanning(found: [DiscoveredPeripheral])
    /// `name` is `nil` when the peripheral didn't advertise one.
    case connecting(name: String?)
    case connected(isStreaming: Bool)
    case reconnecting(attempt: Int)
    case disconnecting
    case failed
}
