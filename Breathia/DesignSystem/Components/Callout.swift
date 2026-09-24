import SwiftUI

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
