import SwiftUI

/// A tile for each app icon, for `AppIconSection` to lay out.
struct AppIconTiles: View {
    let onSelect: (AppIconVariant) -> Void

    @Environment(AppIconStore.self) private var iconStore

    var body: some View {
        ForEach(AppIconVariant.allCases) { icon in
            AppIconTile(icon: icon, isSelected: icon == iconStore.current) {
                onSelect(icon)
            }
        }
    }
}
