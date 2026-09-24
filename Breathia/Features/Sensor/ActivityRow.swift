import SwiftUI

struct ActivityRow: View {
    let text: LocalizedStringKey

    var body: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .listRowBackground(Color.clear)
    }
}

#if DEBUG
#Preview {
    List {
        ActivityRow(text: "sensor.searchingForNearbySensors")
    }
}
#endif
