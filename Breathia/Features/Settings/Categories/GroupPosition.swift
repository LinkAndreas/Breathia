import SwiftUI

/// Where a row sits in its group, which decides which corners of the group's card it rounds.
enum GroupPosition {
    case single, first, middle, last
}

#if os(macOS)
extension View {
    /// A roomy row on its group's card. Mac lists have no grouped style, so each row
    /// draws its slice of the card — rounded at the group's first and last row — and
    /// the groups read as separate blocks, like the grouped forms beside them.
    func macListRow(in position: GroupPosition) -> some View {
        let radius: CGFloat = 10
        let roundsTop = position == .single || position == .first
        let roundsBottom = position == .single || position == .last
        return padding(.vertical, 5)
            .padding(.horizontal, 6)
            .listRowSeparator(.hidden)
            .listRowBackground(
                UnevenRoundedRectangle(
                    topLeadingRadius: roundsTop ? radius : 0,
                    bottomLeadingRadius: roundsBottom ? radius : 0,
                    bottomTrailingRadius: roundsBottom ? radius : 0,
                    topTrailingRadius: roundsTop ? radius : 0,
                    style: .continuous
                )
                .fill(Theme.Palette.elevated)
                // The same inset as the list's selection highlight, so it fills the card.
                .padding(.horizontal, 10)
            )
    }
}
#endif
