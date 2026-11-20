import SwiftUI

extension SettingsPage {
    var title: String {
        switch self {
        case .sensor: String(localized: "common.heartRateSensor")
        case .breathing: String(localized: "settings.breathing")
        case .sound: String(localized: "settings.sound")
        case .biofeedback: String(localized: "settings.biofeedback")
        case .health: String(localized: "settings.appleHealth")
        case .appearance: String(localized: "settings.appearance")
        case .history: String(localized: "history.title")
        case .privacy: String(localized: "common.privacy")
        case .aboutSensor: String(localized: "common.aboutBluetoothSensors")
        }
    }

    var systemImage: String {
        switch self {
        case .sensor: "antenna.radiowaves.left.and.right"
        case .breathing: "wind"
        case .sound: "speaker.wave.2.fill"
        case .biofeedback: "waveform.path.ecg"
        case .health: "heart.fill"
        case .appearance: "circle.lefthalf.filled"
        case .history: "clock.fill"
        case .privacy: "hand.raised.fill"
        case .aboutSensor: "info"
        }
    }

    var tone: SettingsTone {
        switch self {
        case .sensor: .heart
        case .breathing: .breathing
        case .sound: .sound
        case .biofeedback: .biofeedback
        case .health: .health
        case .appearance: .appearance
        case .history: .history
        case .privacy: .privacy
        case .aboutSensor: .information
        }
    }
}
