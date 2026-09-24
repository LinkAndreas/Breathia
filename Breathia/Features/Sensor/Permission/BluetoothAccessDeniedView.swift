import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Bluetooth access was denied: how to allow it, and that sessions work without it.
struct BluetoothAccessDeniedView: View {
    @Environment(\.openURL) private var openURL

    /// The app's page in Settings on iPhone; Privacy & Security › Bluetooth on a Mac.
    private static var settingsURL: URL? {
        #if os(iOS)
        URL(string: UIApplication.openSettingsURLString)
        #else
        URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Bluetooth")
        #endif
    }

    var body: some View {
        Section {
            ContentUnavailableView {
                Label("sensor.denied.title", systemImage: "antenna.radiowaves.left.and.right.slash")
            } description: {
                Text("sensor.denied.message")
            } actions: {
                Button("sensor.denied.openSettings") {
                    if let url = Self.settingsURL {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .listRowBackground(Color.clear)
    }
}
