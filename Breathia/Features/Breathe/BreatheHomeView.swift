import SwiftUI

/// The Breathe section: a compact sensor status, then every technique grouped by
/// category, with native search and category filters. Tapping a technique opens
/// its details; the sensor is connected from the navigation bar.
struct BreatheHomeView: View {
    /// `true` on iPad, where the opened technique stays highlighted next to the
    /// detail column; `false` on iPhone, where rows push and show a chevron.
    let usesSelection: Bool
    let selectedTechniqueID: Technique.ID?
    let onOpen: (Technique.ID) -> Void
    let onShowSensor: () -> Void

    @State private var filter: TechniqueFilter = .all
    @State private var query = ""

    private var groups: [TechniqueGroup] {
        TechniqueGroup.grouping(
            TechniqueCatalog.all.filter { filter.includes($0) && $0.matches(query) }
        )
    }

    #if os(iOS)
    /// Tucked under the large title until the list is pulled down.
    private static let searchPlacement = SearchFieldPlacement.navigationBarDrawer(displayMode: .automatic)
    #else
    /// In the column's toolbar.
    private static let searchPlacement = SearchFieldPlacement.toolbar
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TechniqueFilterBar(selection: $filter)
                    .padding(.top, 8)

                // Changing the filter crossfades the whole list rather than animating
                // each row into place; the ZStack overlaps outgoing and incoming lists
                // so neither pushes the other down. Search results update instantly.
                ZStack(alignment: .top) {
                    TechniqueList(
                        groups: groups,
                        filter: filter,
                        usesSelection: usesSelection,
                        selectedTechniqueID: selectedTechniqueID,
                        onOpen: onOpen
                    )
                    .id(filter)
                    .transition(.opacity)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Theme.Palette.background)
        .navigationTitle("common.breathe")
        #if os(macOS)
        // A Mac window has one title, taken from this column; the open technique
        // shows as its subtitle, as the selected mailbox's details do in Mail.
        .navigationSubtitle(selectedTechniqueID.map { TechniqueCatalog.technique(withID: $0).name } ?? "")
        #endif
        .searchable(text: $query, placement: Self.searchPlacement, prompt: Text("breathe.searchTechniques"))
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SensorToolbarWidget(action: onShowSensor)
            }
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        BreatheHomeView(usesSelection: false, selectedTechniqueID: nil, onOpen: { _ in }, onShowSensor: {})
    }
    .environment(PreviewStores.heartRateMonitor())
}
#endif
