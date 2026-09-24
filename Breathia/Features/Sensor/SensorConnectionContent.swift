import SwiftUI

/// The sensor's rows for its current state: asking for Bluetooth, searching,
/// the sensors found, connecting, or the connected sensor.
struct SensorConnectionContent: View {
    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
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
}
