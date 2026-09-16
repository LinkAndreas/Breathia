#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Opens feedback emails through the system's `mailto:` handling, so the user's
/// preferred mail app is used.
struct SystemFeedbackMailer: FeedbackMailing {
    func compose(_ email: FeedbackEmail) async -> Bool {
        guard let url = email.mailtoURL else { return false }
        #if os(iOS)
        return await UIApplication.shared.open(url)
        #elseif os(macOS)
        return NSWorkspace.shared.open(url)
        #endif
    }
}
