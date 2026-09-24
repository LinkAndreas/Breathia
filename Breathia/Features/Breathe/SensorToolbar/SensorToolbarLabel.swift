import SwiftUI

/// The live heart rate once a sensor is connected, what's happening while it gets
/// there, and "HR Sensor" otherwise.
struct SensorToolbarLabel: View {
    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        switch monitor.status {
        case .connected:
            if let heartRate = monitor.heartRate {
                Text("common.bpm \(heartRate)")
            } else {
                Text(monitor.status.summary)
            }
        case .scanning, .connecting, .reconnecting, .disconnecting:
            Text(monitor.status.summary)
        case .idle, .failed, .unavailable, .needsPermission, .denied:
            Text("breathe.hrSensor", comment: "Short label of the heart-rate sensor button while none is connected")
        }
    }
}

#if DEBUG
#Preview {
    SensorToolbarLabel()
        .padding()
        .environment(PreviewStores.heartRateMonitor())
}
#endif
