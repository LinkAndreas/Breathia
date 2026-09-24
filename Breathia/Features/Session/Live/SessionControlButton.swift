import SwiftUI

/// A large circular session control: a prominent, technique-tinted button for
/// the main action and a red glass button for ending the session.
struct SessionControlButton: View {
    enum Role {
        case primary(Color)
        case destructive
    }

    let title: LocalizedStringKey
    let systemImage: String
    let role: Role
    let diameter: CGFloat
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Group {
                switch role {
                case let .primary(tint):
                    Button(action: action) { SessionControlIcon(systemImage: systemImage, diameter: diameter) }
                        .buttonStyle(.glassProminent)
                        .tint(tint)
                case .destructive:
                    Button(action: action) { SessionControlIcon(systemImage: systemImage, diameter: diameter) }
                        .buttonStyle(.glass)
                        .tint(.red)
                }
            }
            .buttonBorderShape(.circle)
            .accessibilityLabel(title)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(labelColor)
                .accessibilityHidden(true)
        }
    }

    private var labelColor: Color {
        switch role {
        case .primary: .primary
        case .destructive: .red
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 48) {
        SessionControlButton(title: "common.pause", systemImage: "pause.fill", role: .primary(.teal), diameter: 84) {}
        SessionControlButton(title: "common.end", systemImage: "stop.fill", role: .destructive, diameter: 84) {}
    }
    .padding()
}
#endif
