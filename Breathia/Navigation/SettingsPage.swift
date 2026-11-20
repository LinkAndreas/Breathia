import Foundation

/// One settings category or info page.
nonisolated enum SettingsPage: Hashable, Codable, Sendable {
    case sensor
    case breathing
    case sound
    case biofeedback
    case health
    case appearance
    case history
    case privacy
    case aboutSensor
}
