import SwiftUI

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
