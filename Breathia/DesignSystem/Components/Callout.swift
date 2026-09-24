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

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        Callout(text: "Your HRV rose during the session — a sign your body relaxed.")
        Callout(text: "Stop if you feel dizzy or light-headed.", isSecondary: true)
    }
    .padding()
}
#endif
