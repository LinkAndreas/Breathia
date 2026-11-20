import Foundation

/// Breathia's page in the App Store.
enum AppStoreLinks {
    static let appID = "6812983709"

    /// The App Store page, to share the app.
    static let app = URL(string: "https://apps.apple.com/app/id\(appID)")!

    /// The App Store page opened on writing a review — the way Apple suggests to
    /// let people rate an app whenever they choose to.
    static let writeReview = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
}
