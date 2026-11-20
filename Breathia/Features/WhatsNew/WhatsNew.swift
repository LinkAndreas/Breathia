import SwiftUI

/// What a release brings, shown once to people who already used Breathia, and
/// any time from Settings.
enum WhatsNew {
    /// The release these features came with; raising it shows the sheet again.
    static let version = "1.8"

    struct Feature: Identifiable {
        /// Where a feature can be tried right away.
        enum Destination {
            case soundSettings
            case history
            case feedback

            /// The button that goes there.
            var title: LocalizedStringKey {
                switch self {
                case .soundSettings: "whatsNew.openSoundSettings"
                case .history: "whatsNew.openHistory"
                case .feedback: "whatsNew.openFeedback"
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
            id: "sounds", symbol: "speaker.wave.2.fill", color: Color(oklch: 0.62, chroma: 0.15, hue: 285),
            title: "whatsNew.sounds18.title", text: "whatsNew.sounds18.text",
            destination: .soundSettings
        ),
        Feature(
            id: "charts", symbol: "waveform.path.ecg", color: Color(oklch: 0.62, chroma: 0.15, hue: 352),
            title: "whatsNew.charts.title", text: "whatsNew.charts.text",
            destination: .history
        ),
        Feature(
            id: "feedback", symbol: "star.fill", color: Color(oklch: 0.68, chroma: 0.14, hue: 78),
            title: "whatsNew.feedback.title", text: "whatsNew.feedback.text",
            destination: .feedback
        ),
    ]

    /// After an update, for people who already used Breathia; new users get the
    /// onboarding instead.
    static func shouldShow(lastSeen: String?, hasCompletedOnboarding: Bool) -> Bool {
        hasCompletedOnboarding && lastSeen != version
    }
}
