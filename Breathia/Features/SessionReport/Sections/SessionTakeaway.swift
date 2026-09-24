import SwiftUI

/// The breathing pattern and what the session showed.
struct SessionTakeaway: View {
    let session: SessionRecord

    var body: some View {
        VStack(spacing: 20) {
            Pill(text: session.technique.patternLabel, tint: session.technique.tint)

            Callout(text: session.summaryText)
        }
    }
}

#if DEBUG
#Preview {
    SessionTakeaway(session: PreviewData.sessions[0])
        .padding()
}
#endif
