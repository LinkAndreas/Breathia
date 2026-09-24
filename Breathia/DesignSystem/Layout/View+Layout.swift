import SwiftUI

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
