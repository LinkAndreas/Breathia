import SwiftUI

/// One new feature: its symbol, what it is, and where to try it.
struct WhatsNewFeatureRow: View {
    let feature: WhatsNew.Feature
    let onTry: (WhatsNew.Feature.Destination) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.symbol)
                .font(.title2)
                .foregroundStyle(feature.color)
                .frame(width: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.text)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let destination = feature.destination {
                    Button("whatsNew.openSoundSettings") { onTry(destination) }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderless)
                        .padding(.top, 4)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
