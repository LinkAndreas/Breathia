import Foundation

/// Pages on Breathia's website. Each is published in every language the app supports and
/// opens in the language the app runs in.
enum WebsiteLinks {
    static var privacyPolicy: URL { page("privacy") }

    /// The app's languages (by language code), each with the path of its pages on the website;
    /// any other language gets English.
    private static let languages: [String: String] = [
        "de": "de", "en": "en", "es": "es", "fr": "fr", "it": "it",
        "ja": "ja", "ko": "ko", "nl": "nl", "pt": "pt-br", "ru": "ru", "zh": "zh",
    ]

    private static func page(_ name: String) -> URL {
        let language = Bundle.main.preferredLocalizations.first
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            .flatMap { languages[$0] } ?? "en"
        return URL(string: "https://breathia.linkandreas.de/\(name)/\(language)/")!
    }
}
