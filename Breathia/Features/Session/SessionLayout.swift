import SwiftUI

/// How the session screens divide the screen. The countdown, the live session, and
/// the report share it, so the countdown's ring sits where the breathing circle
/// takes over, and a finished session is laid out the same way.
enum SessionLayout {
    /// One column, circle in the middle.
    case stacked
    /// The circle in the leading pane; everything else beside it.
    case sideBySide(leadingWidth: CGFloat, gap: CGFloat)
    /// The circle above, the controls below.
    case aboveAndBelow(topHeight: CGFloat, gap: CGFloat)

    /// Room kept clear either side of a display's crease.
    private static let creaseGap: CGFloat = 48
    private static let paneGap: CGFloat = 24
    /// The least a pane beside the crease needs; a narrower one — a split view
    /// column that only just reaches over the crease — isn't worth splitting.
    private static let minimumPaneLength: CGFloat = 280

    /// Splits the screen at a partly folded display's crease, so nothing sits on
    /// the bend: the circle faces the user and the controls lie within reach. A
    /// wide screen — an unfolded iPhone or an iPad in landscape — sets the circle
    /// beside the rest instead of leaving the sides empty.
    ///
    /// - Parameter frame: The screen's content area, in the global coordinate space.
    init(in frame: CGRect, fold: DisplayFold?, layoutDirection: LayoutDirection) {
        if let fold {
            let margin = Self.minimumPaneLength + Self.creaseGap / 2
            switch fold.axis {
            case .vertical where frame.minX + margin <= fold.position && fold.position <= frame.maxX - margin:
                let leadingWidth = layoutDirection == .rightToLeft
                    ? frame.maxX - fold.position
                    : fold.position - frame.minX
                self = .sideBySide(leadingWidth: leadingWidth - Self.creaseGap / 2, gap: Self.creaseGap)
                return
            case .horizontal where frame.minY + margin <= fold.position && fold.position <= frame.maxY - margin:
                self = .aboveAndBelow(topHeight: fold.position - frame.minY - Self.creaseGap / 2, gap: Self.creaseGap)
                return
            default:
                break
            }
        }
        // Tall enough for the controls and cards beside the circle; a phone in
        // landscape isn't.
        if frame.width > frame.height * 1.2 && frame.height >= 480 {
            self = .sideBySide(leadingWidth: (frame.width - Self.paneGap) / 2, gap: Self.paneGap)
        } else {
            self = .stacked
        }
    }
}
