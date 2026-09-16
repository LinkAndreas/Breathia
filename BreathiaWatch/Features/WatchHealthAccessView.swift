import SwiftUI

/// Shown before the first session: why Breathia asks for Health access on
/// Apple Watch — the heart rate during a session, and saving the session to Health.
/// The system permission sheet follows when the user continues.
struct WatchHealthAccessView: View {
    let onContinue: () -> Void

    @State private var isRequesting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.red.gradient)
                    .symbolEffect(.pulse)
                    .accessibilityHidden(true)

                Text("watch.health.title")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("watch.health.message")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("watch.health.continue") {
                    isRequesting = true
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(isRequesting)
                .padding(.top, 4)
            }
        }
    }
}

#if DEBUG
#Preview {
    WatchHealthAccessView(onContinue: {})
}
#endif
