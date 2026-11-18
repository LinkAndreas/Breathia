import SwiftUI

/// A link at the end of an info page that opens a web page in the browser.
struct InfoPageLink: View {
    let title: LocalizedStringKey
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            Label(title, systemImage: "arrow.up.right.square")
                .font(.body.weight(.semibold))
        }
    }
}

#if DEBUG
#Preview {
    InfoPageLink(title: "settings.info.readThePrivacyPolicy", destination: WebsiteLinks.privacyPolicy)
        .padding()
}
#endif
