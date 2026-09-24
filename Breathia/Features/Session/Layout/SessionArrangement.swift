import SwiftUI

/// How the session screens divide the screen: the circle (primary) and everything
/// else (secondary), side by side on a wide screen and one above the other on a
/// tall one. On a partly folded display the split follows the crease, so nothing
/// sits on the bend: the circle faces the user and the controls lie within reach.
///
/// The countdown, the live session, and the report share it, so the countdown's
/// ring sits where the breathing circle takes over, and a finished session is laid
/// out the same way.
struct SessionArrangement<Primary: View, Secondary: View>: View {
    /// The axes the split may use. Limited to `.horizontal`, a tall screen shows
    /// the primary view alone.
    private let axes: Axis.Set
    /// The primary view, told whether the secondary view is shown beside or below it.
    private let primary: (_ isSplit: Bool) -> Primary
    private let secondary: Secondary

    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    init(
        axes: Axis.Set = [.horizontal, .vertical],
        @ViewBuilder primary: @escaping (_ isSplit: Bool) -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.axes = axes
        self.primary = primary
        self.secondary = secondary()
    }

    /// An arrangement whose primary view is the same whether or not the secondary
    /// view is shown.
    init(
        axes: Axis.Set = [.horizontal, .vertical],
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        let primary = primary()
        self.init(axes: axes, primary: { _ in primary }, secondary: secondary)
    }

    var body: some View {
        #if os(iOS)
        if verticalSizeClass == .compact {
            // Where the height is compact — a phone on its side, iPhone Duo's outer
            // display — an arrangement collapses to its primary view, as a split
            // view does. The session needs both, so they sit side by side; the
            // report, which splits only side by side anyway, shows one column.
            if axes.contains(.vertical) {
                HStack(spacing: 0) {
                    primary(true)
                    secondary
                }
            } else {
                primary(false)
            }
        } else if #available(iOS 27.1, *) {
            SplitSessionArrangement(axes: axes, primary: primary, secondary: secondary)
        } else {
            ProportionalSessionArrangement(axes: axes, primary: primary, secondary: secondary)
        }
        #else
        // TODO: Use ArrangementView on the Mac too once the macOS SDK has it (it's
        // iOS-only in Xcode 27.1).
        ProportionalSessionArrangement(axes: axes, primary: primary, secondary: secondary)
        #endif
    }
}

#if DEBUG
#Preview {
    SessionArrangement {
        Circle().fill(.teal.opacity(0.3)).padding()
    } secondary: {
        Text(verbatim: "Secondary")
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(.gray.opacity(0.2))
    }
}
#endif
