import Foundation

extension ConnectionStatus {
    var summary: String {
        switch self {
        case .needsPermission: String(
            localized: "sensor.status.notConnected",
            comment: "Sensor connection status"
        )
        case .denied: String(
            localized: "sensor.status.noBluetoothAccess",
            comment: "Sensor connection status: the user denied Bluetooth access"
        )
        case .unavailable: String(
            localized: "sensor.status.unavailable",
            comment: "Sensor connection status"
        )
        case .idle: String(
            localized: "sensor.status.notConnected",
            comment: "Sensor connection status"
        )
        case .scanning: String(
            localized: "sensor.status.searching",
            comment: "Sensor connection status"
        )
        case .connecting: String(
            localized: "sensor.status.connecting",
            comment: "Sensor connection status"
        )
        case .connected: String(
            localized: "sensor.status.connected",
            comment: "Sensor connection status"
        )
        case .reconnecting: String(
            localized: "sensor.status.reconnecting",
            comment: "Sensor connection status"
        )
        case .disconnecting: String(
            localized: "common.disconnecting",
            comment: "Sensor connection status"
        )
        case .failed: String(
            localized: "sensor.status.connectionFailed",
            comment: "Sensor connection status"
        )
        }
    }
}

extension HeartRateMonitor {
    /// The live heart rate while connected, otherwise the connection state.
    var statusDetail: String {
        if isConnected, let heartRate {
            String(localized: "common.bpm \(heartRate)")
        } else {
            status.summary
        }
    }
}
