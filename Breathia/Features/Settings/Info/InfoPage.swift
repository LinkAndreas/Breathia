import SwiftUI

struct InfoPage: View {
    struct Section {
        let heading: LocalizedStringKey
        let body: LocalizedStringKey
    }

    struct WebLink {
        let title: LocalizedStringKey
        let destination: URL
    }

    let title: LocalizedStringKey
    let sections: [Section]
    var link: WebLink?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(sections.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sections[index].heading)
                            .font(.headline)
                        Text(sections[index].body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                }
                if let link {
                    InfoPageLink(title: link.title, destination: link.destination)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .readableContentWidth()
        }
        .background(Theme.Palette.background)
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        InfoPage(title: "common.privacy", sections: [
            .init(heading: "settings.info.yourDataStays", body: "settings.info.heartRateReadingsHRV"),
        ])
    }
}
#endif
