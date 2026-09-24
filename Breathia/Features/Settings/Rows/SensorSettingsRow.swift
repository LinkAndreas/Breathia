import SwiftUI

/// Sensor status that opens the sensor sheet (iPhone).
struct SensorSettingsRow: View {
    let action: () -> Void

    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        Button(action: action) {
            LabeledContent {
                HStack(spacing: 6) {
                    StatusDot(isActive: monitor.isConnected)
                    Text(monitor.statusDetail)
                        .monospacedDigit()
                }
            } label: {
                SettingsLabel(
                    verbatim: monitor.sensorName,
                    systemImage: SettingsPage.sensor.systemImage,
                    color: SettingsPage.sensor.iconColor
                )
            }
        }
        .tint(.primary)
    }
}
