import Foundation

/// Facts about the running app and device, attached to feedback so support can
/// reproduce problems.
struct AppMetadata: Equatable {
    let appName: String
    let appVersion: String
    let buildNumber: String
    /// The hardware identifier, e.g. "iPhone17,1".
    let deviceModel: String
    let systemName: String
    let systemVersion: String
    let localeIdentifier: String
}

/// A feedback email to support, with the app and device details at the bottom.
struct FeedbackEmail: Equatable {
    static let supportAddress = "feedback@linkandreas.de"

    let recipient: String
    let subject: String
    let body: String

    /// - Parameters:
    ///   - subject: The localized subject line.
    ///   - prompt: Localized text inviting the user to write; the cursor goes below it.
    init(subject: String, prompt: String, metadata: AppMetadata, recipient: String = Self.supportAddress) {
        self.recipient = recipient
        self.subject = subject
        self.body = """
        \(prompt)



        —
        App: \(metadata.appName) \(metadata.appVersion) (\(metadata.buildNumber))
        Device: \(metadata.deviceModel)
        System: \(metadata.systemName) \(metadata.systemVersion)
        Language: \(metadata.localeIdentifier)
        """
    }

    /// A `mailto:` link that opens the user's mail app with everything filled in.
    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}
