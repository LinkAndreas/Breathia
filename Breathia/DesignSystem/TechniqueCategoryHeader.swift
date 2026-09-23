import SwiftUI

/// Section header naming a technique category, used wherever techniques are grouped.
struct TechniqueCategoryHeader: View {
    let category: TechniqueCategory

    var body: some View {
        CardListHeader {
            Label(category.title, systemImage: category.systemImage)
        }
    }
}

/// Section header over a list of cards: techniques by category, sessions by when
/// they happened.
struct CardListHeader<Title: View>: View {
    @ViewBuilder let title: Title

    var body: some View {
        title
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
