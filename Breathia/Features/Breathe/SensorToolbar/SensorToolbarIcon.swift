import SwiftUI

/// A pulsing heart once a sensor is connected, progress while it gets there, and
/// the sensor symbol otherwise.
struct SensorToolbarIcon: View {
    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        switch monitor.status {
        case .connected:
            Image(systemName: "heart.fill")
                .symbolEffect(.pulse, isActive: monitor.heartRate != nil)
        case .scanning, .connecting, .reconnecting, .disconnecting:
            ProgressView()
                .controlSize(.small)
        case .idle, .failed, .unavailable, .needsPermission, .denied:
            // The sensor symbol; the heart appears once a sensor is connected.
            Image(systemName: "antenna.radiowaves.left.and.right")
        }
    }
}
