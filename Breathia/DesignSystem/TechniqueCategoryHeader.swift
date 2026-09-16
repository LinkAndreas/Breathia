import SwiftUI

/// Section header naming a technique category, used wherever techniques are grouped.
struct TechniqueCategoryHeader: View {
    let category: TechniqueCategory

    var body: some View {
        Label(category.title, systemImage: category.systemImage)
            .font(.footnote.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 6)
            .accessibilityAddTraits(.isHeader)
    }
}
