import SwiftUI

/// One category chip; the selected one wears the highlight capsule that slides
/// between the chips.
struct TechniqueFilterChip: View {
    let filter: TechniqueFilter
    let isSelected: Bool
    /// Shared by the bar's chips, so the highlight moves from one to the next.
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(filter.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    } else {
                        Capsule()
                            .fill(Theme.Palette.elevated)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
