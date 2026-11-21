import SwiftUI

/// The whole report in one scrolling column, its action kept in reach at the bottom.
struct SessionReportColumn<Header: View, Action: View>: View {
    let session: SessionRecord
    /// What the page is about: the technique and how long it ran.
    let header: Header
    /// The page's one action, such as Done.
    let action: Action

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                SessionMeasurements(session: session)
                SessionTakeaway(session: session)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
            .readableContentWidth()
        }
        #if DEBUG
        .defaultScrollAnchor(ScreenshotScreen.requested == .historyCharts ? UnitPoint(x: 0.5, y: 0.75) : nil)
        #endif
        .safeAreaBar(edge: .bottom) {
            if Action.self != EmptyView.self {
                action
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .readableContentWidth()
            }
        }
    }
}

#if DEBUG
#Preview {
    SessionReportColumn(
        session: PreviewData.sessions[0],
        header: HistorySessionHeader(technique: PreviewData.sessions[0].technique, subtitle: Formatters.clock(PreviewData.sessions[0].duration)),
        action: PrimaryActionButton(title: "common.done") {}
    )
}
#endif
