import SwiftUI

/// An action among the categories of the iPad and Mac settings list: it does
/// something rather than opening a page, so it isn't selectable, and on the Mac it
/// draws its slice of its group's card like the category rows.
struct CategoryListAction: ViewModifier {
    let position: GroupPosition

    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .buttonStyle(.plain)
            .macListRow(in: position)
            #endif
    }
}
