import SwiftUI

struct SupportHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 52))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
            Text("support.supportBreathia")
                .font(.title2.bold())
            Text("support.breathiaIsFree")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    SupportHeader()
        .padding()
}
#endif
