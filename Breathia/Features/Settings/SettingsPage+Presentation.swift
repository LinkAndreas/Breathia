import SwiftUI

extension SettingsPage {
    var title: String {
        switch self {
        case .sensor: String(localized: "common.heartRateSensor")
        case .breathing: String(localized: "settings.breathing")
        case .biofeedback: String(localized: "settings.biofeedback")
        case .health: String(localized: "settings.appleHealth")
        case .appearance: String(localized: "settings.appearance")
        case .privacy: String(localized: "common.privacy")
        case .aboutSensor: String(localized: "common.aboutBluetoothPolarH10")
        }
    }

    var systemImage: String {
        switch self {
        case .sensor: "antenna.radiowaves.left.and.right"
        case .breathing: "wind"
        case .biofeedback: "waveform.path.ecg"
        case .health: "heart.fill"
        case .appearance: "circle.lefthalf.filled"
        case .privacy: "hand.raised.fill"
        case .aboutSensor: "info"
        }
    }

    var iconColor: Color {
        switch self {
        case .sensor: .red
        case .breathing: .teal
        case .biofeedback: .green
        case .health: .pink
        case .appearance: .indigo
        case .privacy: .blue
        case .aboutSensor: .gray
        }
    }
}
