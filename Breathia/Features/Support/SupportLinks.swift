import Foundation

/// Links shown with the purchase options, as App Review requires for subscriptions.
enum SupportLinks {
    /// Apple's standard license agreement. Replace if you publish custom terms.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// The privacy policy in the app's language: published in German and English,
    /// so every other language gets English.
    static var privacyPolicy: URL {
        let language = Bundle.main.preferredLocalizations.first?.hasPrefix("de") == true ? "de" : "en"
        return URL(string: "https://www.linkandreas.de/breathia/privacy/\(language)")!
    }
}
