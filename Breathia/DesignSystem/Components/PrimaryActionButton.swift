import SwiftUI

/// Full-width prominent Liquid Glass button used for a screen's main action.
struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(tint)
    }
}

#if DEBUG
#Preview {
    PrimaryActionButton(title: "technique.detail.startThisTechnique", tint: .teal) {}
        .padding()
}
#endif
