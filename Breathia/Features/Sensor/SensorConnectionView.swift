import SwiftUI

/// Finds, connects to, and disconnects the heart-rate sensor. Presented as a sheet
/// on iPhone and as the Heart Rate Sensor settings page on iPad. Leaving the view
/// stops a scan that is still running.
///
/// The first time, it explains why Bluetooth is needed before the system asks for it, and
/// if access was denied it says how to allow it.
struct SensorConnectionView: View {
    /// Whether appearing starts a scan right away (the sheet) or waits for the
    /// user to tap Search (the settings page).
    var scansOnAppear = true

    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        Group {
            #if os(macOS)
            // Sections as grouped cards, like System Settings; a Mac list has none. Set
            // here rather than inherited, since this form is also shown in a sheet.
            Form { SensorConnectionContent() }
                .formStyle(.grouped)
            #else
            List { SensorConnectionContent() }
            #endif
        }
        .onAppear {
            if scansOnAppear { scanIfIdle() }
        }
        .onDisappear(perform: monitor.stopScan)
    }

    private func scanIfIdle() {
        switch monitor.status {
        case .idle, .failed: monitor.startScan()
        default: break
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SensorConnectionView(scansOnAppear: false)
    }
    .environment(PreviewStores.heartRateMonitor())
}
#endif
