import SwiftUI

/// The sensor widget's button: the sensor's icon and a short status beside it.
struct SensorToolbarButton: View {
    let action: () -> Void

    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                SensorToolbarIcon()
                SensorToolbarLabel()
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            #if os(iOS)
            .font(.subheadline.weight(.semibold))
            #else
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            #endif
            .animation(.snappy, value: monitor.heartRate)
            .animation(.snappy, value: monitor.status)
        }
        .accessibilityLabel(Text("common.heartRateSensor"))
        .accessibilityValue(Text(monitor.statusDetail))
        .accessibilityHint(Text("breathe.opensHeartRateSensor"))
    }
}
