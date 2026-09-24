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

#if DEBUG
#Preview {
    TechniqueCategoryHeader(category: TechniqueCatalog.all[1].category)
}
#endif
