import StoreKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Requests the App Store rating dialog in the app's active window.
struct StoreKitReviewRequester: ReviewRequesting {
    func requestReview() {
        #if os(iOS)
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        guard let scene else { return }
        AppStore.requestReview(in: scene)
        #elseif os(macOS)
        guard let controller = NSApplication.shared.keyWindow?.contentViewController else { return }
        AppStore.requestReview(in: controller)
        #endif
    }
}
