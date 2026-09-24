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

#if DEBUG
#Preview {
    NavigationStack {
        WatchTechniqueListView()
    }
}
#endif
