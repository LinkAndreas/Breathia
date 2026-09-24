import SwiftUI

struct TechniqueRow: View {
    let technique: Technique
    let isSelected: Bool
    let showsDisclosure: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                TechniqueOrb(technique: technique, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(technique.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(verbatim: "\(technique.patternLabel) · \(technique.durationLabel)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsDisclosure {
                    DisclosureChevron()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.row))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.row)
                    .strokeBorder(isSelected ? technique.tint : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.plain)
        #if os(iOS)
        // Highlights the card under the pointer on iPad.
        .hoverEffect(.highlight)
        #endif
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 10) {
        TechniqueRow(technique: TechniqueCatalog.all[1], isSelected: false, showsDisclosure: true) {}
        TechniqueRow(technique: TechniqueCatalog.all[0], isSelected: true, showsDisclosure: false) {}
    }
    .padding()
}
#endif
