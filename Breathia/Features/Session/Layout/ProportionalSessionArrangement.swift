import SwiftUI

/// A session arrangement laid out from the space it's given: side by side where
/// it's wide and tall enough for the controls and cards beside the circle, one
/// above the other otherwise. The Mac's layout, and iPhone and iPad's before
/// `ArrangementView` (iOS 27.1).
struct ProportionalSessionArrangement<Primary: View, Secondary: View>: View {
    /// The axes the arrangement may use.
    let axes: Axis.Set
    /// The primary view, told whether the secondary view is shown beside or below it.
    let primary: (_ isSplit: Bool) -> Primary
    let secondary: Secondary

    var body: some View {
        GeometryReader { proxy in
            // Tall enough for the controls and cards beside the circle.
            let isWide = proxy.size.width > proxy.size.height * 1.2 && proxy.size.height >= 480
            if isWide && axes.contains(.horizontal) {
                HStack(spacing: 24) {
                    primary(true)
                        .frame(width: (proxy.size.width - 24) / 2)
                    secondary
                }
            } else if axes.contains(.vertical) {
                VStack(spacing: 0) {
                    primary(true)
                    secondary
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                primary(false)
            }
        }
    }
}

#if DEBUG
#Preview {
    ProportionalSessionArrangement(
        axes: [.horizontal, .vertical],
        primary: { isSplit in
            Circle().fill(.teal.opacity(isSplit ? 0.3 : 0.6)).padding()
        },
        secondary: Text(verbatim: "Secondary")
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(.gray.opacity(0.2))
    )
}
#endif
