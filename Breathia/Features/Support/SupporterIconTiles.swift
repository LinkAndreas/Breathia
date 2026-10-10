import SwiftUI

/// A tile for each supporter app icon, for `SupporterIconsSection` to lay out.
struct SupporterIconTiles: View {
    let isUnlocked: Bool
    let lockedTapCount: Int
    let onSelect: (SupporterIcon) -> Void

    @Environment(AppIconStore.self) private var iconStore

    var body: some View {
        ForEach(SupporterIcon.allCases) { icon in
            SupporterIconTile(
                icon: icon,
                isSelected: icon == iconStore.current,
                isLocked: !isUnlocked && icon != .classic,
                lockedTapCount: lockedTapCount
            ) {
                onSelect(icon)
            }
        }
    }
}
