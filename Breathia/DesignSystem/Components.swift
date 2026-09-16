import SwiftUI

struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.footnote)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 6)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Full-width prominent Liquid Glass button used for a screen's main action.
struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(tint)
    }
}

struct Pill: View {
    enum Size { case regular, small }

    let text: String
    let tint: Color
    var size: Size = .regular

    var body: some View {
        Text(text)
            .font(size == .regular ? .subheadline.weight(.semibold) : .footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, size == .regular ? 16 : 12)
            .padding(.vertical, size == .regular ? 8 : 6)
            .background(Theme.Palette.subtleFill, in: .capsule)
    }
}

struct Callout: View {
    let text: String
    var isSecondary = false

    var body: some View {
        Text(text)
            .font(isSecondary ? .footnote : .subheadline)
            .foregroundStyle(isSecondary ? .secondary : .primary)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.Palette.calloutFill, in: .rect(cornerRadius: Theme.Radius.callout))
    }
}

struct StatusDot: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(isActive ? Theme.Palette.connected : Theme.Palette.disconnected)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Places content on the elevated card surface.
    func cardSurface(horizontalPadding: CGFloat = 16, verticalPadding: CGFloat = 14) -> some View {
        padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.card))
    }

    /// Caps content at a comfortable reading width and centres it — keeps detail
    /// screens from stretching edge to edge on iPad.
    func readableContentWidth(_ maxWidth: CGFloat = 640) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
