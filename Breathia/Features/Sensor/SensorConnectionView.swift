import SwiftUI
#if os(iOS)
import UIKit
#endif

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
        container
            .onAppear {
                if scansOnAppear { scanIfIdle() }
            }
            .onDisappear(perform: monitor.stopScan)
    }

    @ViewBuilder
    private var container: some View {
        #if os(macOS)
        // Sections as grouped cards, like System Settings; a Mac list has none. Set
        // here rather than inherited, since this form is also shown in a sheet.
        Form { content }
            .formStyle(.grouped)
        #else
        List { content }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        switch monitor.status {
        case .needsPermission:
            BluetoothPermissionPrimer(isRequesting: monitor.isRequestingPermission, onContinue: monitor.requestPermission)

        case .denied:
            BluetoothAccessDeniedView()

        case .unavailable:
            ContentUnavailableView(
                "sensor.bluetoothUnavailable",
                systemImage: "antenna.radiowaves.left.and.right.slash",
                description: Text("sensor.turnOnBluetooth")
            )
            .listRowBackground(Color.clear)

        case .idle:
            Section {
                Button("sensor.searchForSensors", action: monitor.startScan)
            } footer: {
                Text("sensor.moistenTheStrapsElectrodes")
            }

        case .failed:
            Section {
                Button("common.tryAgain", action: monitor.startScan)
            } header: {
                Text("sensor.couldntConnect")
            }

        case let .scanning(found):
            if found.isEmpty {
                ActivityRow(text: "sensor.searchingForNearbySensors")
            } else {
                Section {
                    ForEach(found) { sensor in
                        Button {
                            monitor.connect(to: sensor)
                        } label: {
                            HStack {
                                Text(sensor.name ?? String(localized: "sensor.unknownSensor"))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("sensor.tapToConnect").foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("sensor.nearbySensors")
                        Spacer()
                        ProgressView().controlSize(.small)
                    }
                }
            }

        case let .connecting(name):
            ActivityRow(text: "sensor.connectingTo \(name ?? String(localized: "sensor.unknownSensor"))")

        case let .reconnecting(attempt):
            ActivityRow(text: "sensor.reconnectingAttempt \(attempt)")
            Section {
                Button("sensor.stopReconnecting", role: .destructive, action: monitor.disconnect)
            }

        case .disconnecting:
            ActivityRow(text: "common.disconnecting")

        case .connected:
            Section {
                HStack(spacing: 8) {
                    StatusDot(isActive: true)
                    Text("sensor.connectedTo \(monitor.sensorName)")
                }
                if let heartRate = monitor.heartRate {
                    LabeledContent("common.heartRate", value: String(localized: "common.bpm \(heartRate)"))
                }
            }
            Section {
                Button("sensor.disconnect", role: .destructive, action: monitor.disconnect)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func scanIfIdle() {
        switch monitor.status {
        case .idle, .failed: monitor.startScan()
        default: break
        }
    }
}

/// Explains why Breathia needs Bluetooth before the system asks, so its
/// prompt never comes out of nowhere.
private struct BluetoothPermissionPrimer: View {
    let isRequesting: Bool
    let onContinue: () -> Void

    var body: some View {
        Section {
            VStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(Color.red.gradient)
                        }
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.gradient, in: .circle)
                        .overlay(Circle().stroke(Theme.Palette.background, lineWidth: 3))
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("sensor.permission.title")
                        .font(.title3.bold())
                    Text("sensor.permission.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                // The lock sits beside the first line of the text, not off to the
                // side of a centred paragraph.
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "lock.fill")
                        .accessibilityHidden(true)
                    Text("sensor.permission.privacy")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    PrimaryActionButton(title: "sensor.permission.continue", tint: .blue, action: onContinue)
                        .disabled(isRequesting)
                        #if os(macOS)
                        .frame(maxWidth: 260)
                        #endif
                    Text("sensor.permission.next")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12)
            // Kept to a readable width in wide columns on iPad and Mac.
            .readableContentWidth(480)
        }
        .listRowBackground(Color.clear)
    }
}

/// Bluetooth access was denied: how to allow it, and that sessions work without it.
private struct BluetoothAccessDeniedView: View {
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

private struct ActivityRow: View {
    let text: LocalizedStringKey

    var body: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .listRowBackground(Color.clear)
    }
}
