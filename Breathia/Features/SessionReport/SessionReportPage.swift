import SwiftUI

/// A finished session's page — shared by the results screen and the History
/// detail screen. One scrolling column; on a wide screen, or either side of a
/// partly folded display's crease, the summary beside the measurements.
struct SessionReportPage<Header: View, Action: View>: View {
    let session: SessionRecord
    /// What the page is about: the technique and how long it ran.
    @ViewBuilder let header: Header
    /// The page's one action, such as Done; kept in reach at the bottom of a
    /// scrolling column.
    @ViewBuilder let action: Action

    var body: some View {
        // Only side by side: one above the other, each half would scroll on its own.
        // A tall screen shows the whole page in one column instead.
        SessionArrangement(axes: .horizontal) { isSplit in
            if isSplit {
                SessionReportPane {
                    header
                    SessionTakeaway(session: session)
                    action
                }
            } else {
                SessionReportColumn(session: session, header: header, action: action)
            }
        } secondary: {
            SessionReportPane {
                SessionMeasurements(session: session)
            }
        }
    }
}

extension SessionReportPage where Action == EmptyView {
    init(session: SessionRecord, @ViewBuilder header: () -> Header) {
        self.init(session: session, header: header, action: { EmptyView() })
    }
}
