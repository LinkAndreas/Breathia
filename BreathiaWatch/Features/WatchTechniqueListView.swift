import SwiftUI

struct WatchTechniqueListView: View {
    var body: some View {
        List {
            ForEach(TechniqueGroup.grouping(TechniqueCatalog.all)) { group in
                Section(group.category.title) {
                    ForEach(group.techniques) { technique in
                        NavigationLink(value: technique.id) {
                            WatchTechniqueRow(technique: technique)
                        }
                    }
                }
            }
        }
        .navigationTitle("common.breathe")
    }
}

private struct WatchTechniqueRow: View {
    let technique: Technique

    var body: some View {
        HStack(spacing: 10) {
            TechniqueOrb(technique: technique, size: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(technique.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(verbatim: "\(technique.shortPattern) · \(technique.durationLabel)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchTechniqueListView()
    }
}
#endif
