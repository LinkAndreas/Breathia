import Observation
#if os(iOS)
import UIKit
#endif

/// The icon Breathia shows on the Home Screen, which the app takes its accent color and
/// background wash from.
@Observable
final class AppIconStore {
    /// The app's icon.
    private(set) var current: SupporterIcon

    /// Whether the app's icon can be changed here: on iPhone and iPad, but not on a Mac.
    let canChangeIcon: Bool

    @ObservationIgnored private let setAlternateIconName: (String?) async throws -> Void

    /// - Parameters:
    ///   - alternateIconName: The app's alternate icon, as `UIApplication.alternateIconName` gives it.
    ///   - canChangeIcon: Whether the system supports alternate icons.
    ///   - setAlternateIconName: Changes the app's icon, as `UIApplication.setAlternateIconName` does.
    init(
        alternateIconName: String?,
        canChangeIcon: Bool = true,
        setAlternateIconName: @escaping (String?) async throws -> Void
    ) {
        current = SupporterIcon(alternateIconName: alternateIconName)
        self.canChangeIcon = canChangeIcon
        self.setAlternateIconName = setAlternateIconName
    }

    /// Makes `icon` the app's icon. The app follows right away and goes back if the system refuses.
    func select(_ icon: SupporterIcon) async throws {
        guard icon != current else { return }

        let previous = current
        current = icon
        do {
            try await setAlternateIconName(icon.alternateIconName)
        } catch {
            current = previous
            throw error
        }
    }

    /// Goes back to the default icon once recurring support has ended, as the supporter
    /// icons come with it.
    func supportEnded() async {
        try? await select(.classic)
    }
}

extension AppIconStore {
    /// The store for the app's real icon.
    static func live() -> AppIconStore {
        #if os(iOS)
        AppIconStore(
            alternateIconName: UIApplication.shared.alternateIconName,
            canChangeIcon: UIApplication.shared.supportsAlternateIcons
        ) { name in
            try await UIApplication.shared.setAlternateIconName(name)
        }
        #else
        AppIconStore(alternateIconName: nil, canChangeIcon: false) { _ in }
        #endif
    }

    #if DEBUG
    /// A store for previews, which can't change the app's icon.
    static func preview(_ icon: SupporterIcon = .classic) -> AppIconStore {
        AppIconStore(alternateIconName: icon.alternateIconName) { _ in }
    }
    #endif
}
