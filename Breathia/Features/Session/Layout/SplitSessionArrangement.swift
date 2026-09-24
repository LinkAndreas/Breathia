import SwiftUI

#if os(iOS)
/// A session arrangement as a split: the primary view and the secondary view side
/// by side or one above the other, along the crease on a partly folded display.
@available(iOS 27.1, *)
struct SplitSessionArrangement<Primary: View, Secondary: View>: View {
    /// The axes the split may use.
    let axes: Axis.Set
    /// The primary view, told whether the secondary view is shown beside or below it.
    let primary: (_ isSplit: Bool) -> Primary
    let secondary: Secondary

    @State private var isSplit = false

    var body: some View {
        ArrangementView {
            primary(isSplit)
        } secondary: {
            secondary
                // Under the circle, the controls take the height they need and the
                // circle the rest; beside it, each takes half.
                .splitArrangementFixedLayoutSize(horizontal: false, vertical: true)
                // An arrangement that leaves the secondary view out doesn't build
                // it, so this only arrives while it's shown.
                .preference(key: SecondaryShownKey.self, value: true)
        }
        .arrangementViewStyle(.split.axes(axes))
        .onPreferenceChange(SecondaryShownKey.self) { isSplit = $0 }
    }
}

private struct SecondaryShownKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
#endif

#if DEBUG && os(iOS)
@available(iOS 27.1, *)
#Preview {
    SplitSessionArrangement(
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
