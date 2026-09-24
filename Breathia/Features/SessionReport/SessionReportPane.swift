import SwiftUI

/// One side of the report, centred on the screen, scrolling if it outgrows it.
struct SessionReportPane<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
    }
}
