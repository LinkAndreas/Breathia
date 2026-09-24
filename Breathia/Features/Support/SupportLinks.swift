import Foundation

/// Links shown with the purchase options, as App Review requires for subscriptions.
enum SupportLinks {
    /// The privacy policy in the app's language: published in German and English,
    /// so every other language gets English.
    static var privacyPolicy: URL {
        let language = Bundle.main.preferredLocalizations.first?.hasPrefix("de") == true ? "de" : "en"
        return URL(string: "https://www.linkandreas.de/breathia/privacy/\(language)")!
    }
}
