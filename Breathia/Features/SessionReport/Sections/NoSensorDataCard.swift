import SwiftUI

struct NoSensorDataCard: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("report.noSensorData")
                .font(.headline)
            Text("report.polarH10WasntConnected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

#if DEBUG
#Preview {
    NoSensorDataCard()
        .padding()
}
#endif
