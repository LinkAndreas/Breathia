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
