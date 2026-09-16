import SwiftUI

/// A white symbol on a coloured, rounded tile — the icon style of the Settings app.
struct SettingsIcon: View {
    let systemImage: String
    let color: Color

    #if os(macOS)
    private static let side: CGFloat = 22
    #else
    private static let side: CGFloat = 29
    #endif

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: Self.side * 0.52, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: Self.side, height: Self.side)
            .background(color.gradient, in: .rect(cornerRadius: Self.side * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A settings row title with its `SettingsIcon`.
struct SettingsLabel: View {
    private let title: Text
    private let systemImage: String
    private let color: Color

    init(_ title: LocalizedStringKey, systemImage: String, color: Color) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.color = color
    }

    init(verbatim title: String, systemImage: String, color: Color) {
        self.title = Text(verbatim: title)
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        #if os(macOS)
        // Lists on the Mac don't space a custom label icon from its title.
        HStack(spacing: 8) {
            SettingsIcon(systemImage: systemImage, color: color)
            title
        }
        #else
        Label {
            title
        } icon: {
            SettingsIcon(systemImage: systemImage, color: color)
        }
        #endif
    }
}
