import Foundation

/// Pages on Breathia's website. Each is published in every language the app supports and
/// opens in the language the app runs in.
enum WebsiteLinks {
    static var privacyPolicy: URL { page("privacy") }

    /// The app's languages, each with its own page; any other language gets English.
    private static let languages: Set<String> = ["de", "en", "es", "fr"]

    private static func page(_ name: String) -> URL {
        let language = Bundle.main.preferredLocalizations.first
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            .flatMap { languages.contains($0) ? $0 : nil } ?? "en"
        return URL(string: "https://breathia.linkandreas.de/\(name)/\(language)/")!
    }
}
