import SwiftUI

struct InfoPage: View {
    struct Section {
        let heading: LocalizedStringKey
        let body: LocalizedStringKey
    }

    let title: LocalizedStringKey
    let sections: [Section]

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
