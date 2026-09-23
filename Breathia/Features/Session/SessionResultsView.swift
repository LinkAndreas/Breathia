import SwiftUI

struct SessionResultsView: View {
    let session: SessionRecord
    let onDone: () -> Void

    private var tint: Color { session.technique.tint }

    var body: some View {
        SessionReportPage(session: session) {
            VStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(tint, in: .circle)
                    .accessibilityHidden(true)
                Text("common.sessionComplete")
                    .font(.system(size: 26, weight: .bold))
                Text(verbatim: "\(session.technique.name) · \(Formatters.clock(session.duration))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
        } action: {
            PrimaryActionButton(title: "common.done", tint: tint, action: onDone)
        }
    }
}

#if DEBUG
#Preview {
    SessionResultsView(session: PreviewData.sessions[0], onDone: {})
}
#endif
