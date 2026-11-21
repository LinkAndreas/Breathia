import SwiftUI

/// What a release brings, shown once to people who already used Breathia, and
/// any time from Settings.
enum WhatsNew {
    /// The release these features came with; raising it shows the sheet again.
    static let version = "1.8.3"

    struct Feature: Identifiable {
        /// Where a feature can be tried right away.
        enum Destination {
            case soundSettings
            case history
            case feedback
            case versionHistory

            /// The button that goes there.
            var title: LocalizedStringKey {
                switch self {
                case .soundSettings: "whatsNew.openSoundSettings"
                case .history: "whatsNew.openHistory"
                case .feedback: "whatsNew.openFeedback"
                case .versionHistory: "whatsNew.openVersionHistory"
                }
            }
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
            id: "versionHistory", symbol: "clock.arrow.circlepath", color: Color(oklch: 0.62, chroma: 0.13, hue: 212),
            title: "whatsNew.versionHistory.title", text: "whatsNew.versionHistory.text",
            destination: .versionHistory
        ),
        Feature(
            id: "languages", symbol: "globe", color: Color(oklch: 0.62, chroma: 0.14, hue: 160),
            title: "whatsNew.languages.title", text: "whatsNew.languages.text"
        ),
    ]

    /// After an update, for people who already used Breathia; new users get the
    /// onboarding instead.
    static func shouldShow(lastSeen: String?, hasCompletedOnboarding: Bool) -> Bool {
        hasCompletedOnboarding && lastSeen != version
    }
}
