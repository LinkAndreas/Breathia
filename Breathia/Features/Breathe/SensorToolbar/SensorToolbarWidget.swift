import SwiftUI

/// The sensor's state as a navigation bar widget, and the way to connect it:
/// the sensor symbol and "HR Sensor" while disconnected, progress while searching or connecting, and —
/// once a sensor is connected — a green, filled capsule with the live heart rate,
/// so a connected sensor is obvious at a glance. Tapping it opens the sensor sheet.
struct SensorToolbarWidget: View {
    let action: () -> Void

    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        if monitor.isConnected {
            SensorToolbarButton(action: action)
                .buttonStyle(.glassProminent)
                .tint(Theme.Palette.connected)
        } else {
            SensorToolbarButton(action: action)
        }
    }
}
