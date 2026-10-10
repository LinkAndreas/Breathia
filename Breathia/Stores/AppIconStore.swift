import Observation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The icon Breathia shows on the Home Screen, or in the Dock on a Mac. On iPhone and iPad the
/// app takes its accent color and background wash from it.
@Observable
final class AppIconStore {
    /// The app's icon.
    private(set) var current: SupporterIcon

    /// Whether the app's icon can be changed here.
    let canChangeIcon: Bool

    @ObservationIgnored private let setAlternateIconName: (String?) async throws -> Void
    @ObservationIgnored private let defaults: UserDefaults?
    /// The icon a supporter had when their support ended, to bring back if it resumes —
    /// after a failed payment goes through, or a new subscription.
    @ObservationIgnored private var lapsedIcon: SupporterIcon? {
        didSet { defaults?.set(lapsedIcon?.alternateIconName, forKey: Self.lapsedIconKey) }
    }

    /// - Parameters:
    ///   - alternateIconName: The app's alternate icon, as `UIApplication.alternateIconName` gives it.
    ///   - canChangeIcon: Whether the system supports alternate icons.
    ///   - defaults: Where the icon of a supporter whose support ended is kept across launches;
    ///     `nil` keeps it in memory only.
    ///   - setAlternateIconName: Changes the app's icon, as `UIApplication.setAlternateIconName` does.
    init(
        alternateIconName: String?,
        canChangeIcon: Bool = true,
        defaults: UserDefaults? = nil,
        setAlternateIconName: @escaping (String?) async throws -> Void
    ) {
        current = SupporterIcon(alternateIconName: alternateIconName)
        self.canChangeIcon = canChangeIcon
        self.defaults = defaults
        self.setAlternateIconName = setAlternateIconName
        lapsedIcon = defaults?.string(forKey: Self.lapsedIconKey).map(SupporterIcon.init(alternateIconName:))
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
    /// icons come with it, and remembers the one the supporter had. Safe to call again: the
    /// system can refuse the change, e.g. while the app isn't in front.
    func supportEnded() async {
        guard current != .classic else { return }
        lapsedIcon = current
        try? await select(.classic)
    }

    /// Brings back the icon the supporter had when their support ended. Safe to call again.
    func supportResumed() async {
        guard let lapsedIcon else { return }
        // Picked another icon since: that one stays.
        guard current == .classic else {
            self.lapsedIcon = nil
            return
        }
        if (try? await select(lapsedIcon)) != nil {
            self.lapsedIcon = nil
        }
    }
}

extension AppIconStore {
    /// The store for the app's real icon.
    static func live() -> AppIconStore {
        #if os(iOS)
        AppIconStore(
            alternateIconName: UIApplication.shared.alternateIconName,
            canChangeIcon: UIApplication.shared.supportsAlternateIcons,
            defaults: .standard
        ) { name in
            try await UIApplication.shared.setAlternateIconName(name)
        }
        #elseif os(macOS)
        // A Mac app has no alternate icons: Breathia shows the chosen one in the Dock while it
        // runs, and remembers it for the next launch.
        let defaults = UserDefaults.standard
        let name = defaults.string(forKey: macIconKey)
        if name != nil {
            DispatchQueue.main.async { try? showInDock(name) }
        }
        return AppIconStore(alternateIconName: name, defaults: defaults) { name in
            try await MainActor.run { try showInDock(name) }
            defaults.set(name, forKey: macIconKey)
        }
        #else
        AppIconStore(alternateIconName: nil, canChangeIcon: false) { _ in }
        #endif
    }

    private static let lapsedIconKey = "lapsedSupporterIcon"

    #if os(macOS)
    private static let macIconKey = "alternateIconName"

    private struct IconUnavailable: Error {}

    /// Shows the icon named `name` in the Dock, or the app's own icon for `nil`.
    @MainActor
    private static func showInDock(_ name: String?) throws {
        guard let name else {
            NSApp.applicationIconImage = nil
            return
        }
        guard let image = NSImage(named: name) else { throw IconUnavailable() }
        NSApp.applicationIconImage = image
    }
    #endif

    #if DEBUG
    /// A store for previews, which can't change the app's icon.
    static func preview(_ icon: SupporterIcon = .classic) -> AppIconStore {
        AppIconStore(alternateIconName: icon.alternateIconName) { _ in }
    }
    #endif
}
