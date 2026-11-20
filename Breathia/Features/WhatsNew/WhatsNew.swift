import SwiftUI

/// What a release brings, shown once to people who already used Breathia, and
/// any time from Settings.
enum WhatsNew {
    /// The release these features came with; raising it shows the sheet again.
    static let version = "1.6"

    struct Feature: Identifiable {
        /// Where a feature can be tried right away.
        enum Destination {
            case soundSettings
        }

        let id: String
        let symbol: String
        let color: Color
        let title: LocalizedStringKey
        let text: LocalizedStringKey
        var destination: Destination?
    }

    static let features: [Feature] = [
        Feature(
            id: "sounds", symbol: "speaker.wave.2.fill", color: .pink,
            title: "whatsNew.sounds.title", text: "whatsNew.sounds.text",
            destination: .soundSettings
        ),
        Feature(
            id: "rotation", symbol: "rotate.right", color: .blue,
            title: "whatsNew.rotation.title", text: "whatsNew.rotation.text"
        ),
        Feature(
            id: "history", symbol: "trash.fill", color: .orange,
            title: "whatsNew.history.title", text: "whatsNew.history.text"
        ),
    ]

    /// After an update, for people who already used Breathia; new users get the
    /// onboarding instead.
    static func shouldShow(lastSeen: String?, hasCompletedOnboarding: Bool) -> Bool {
        hasCompletedOnboarding && lastSeen != version
    }
}
