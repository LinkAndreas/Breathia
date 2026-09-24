import SwiftUI

/// The techniques, grouped by category under their headers.
struct TechniqueList: View {
    let groups: [TechniqueGroup]
    let filter: TechniqueFilter
    /// `true` on iPad, where the opened technique stays highlighted next to the
    /// detail column; `false` on iPhone, where rows push and show a chevron.
    let usesSelection: Bool
    let selectedTechniqueID: Technique.ID?
    let onOpen: (Technique.ID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(groups) { group in
                // A single chosen category needs no header of its own.
                if filter == .all {
                    TechniqueCategoryHeader(category: group.category)
                }
                LazyVStack(spacing: 10) {
                    ForEach(group.techniques) { technique in
                        TechniqueRow(
                            technique: technique,
                            isSelected: usesSelection && technique.id == selectedTechniqueID,
                            showsDisclosure: !usesSelection
                        ) {
                            onOpen(technique.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, filter == .all ? 0 : 12)
            }
        }
    }
}
