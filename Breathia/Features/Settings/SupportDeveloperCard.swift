import SwiftUI

/// The Support the Developer entry at the top of Settings: a warm gradient card
/// that turns into a thank-you while the user has an active support subscription.
///
/// Drawn with `ConcentricRectangle`, so it takes the shape of the list row it sits
/// in — the row clips to that shape, and a card with its own corner radius would
/// lose its border at the corners.
struct SupportDeveloperCard: View {
    /// The narrower layout for the iPad content column: a smaller icon, one-line
    /// title, at most two lines of text, and no chevron — like the rows around it.
    var isCompact = false

    @Environment(SupportStore.self) private var store

    private var iconSize: CGFloat { isCompact ? 40 : 52 }

    private static let wash = LinearGradient(
        colors: [Color.pink.opacity(0.16), Color.orange.opacity(0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        HStack(spacing: isCompact ? 12 : 14) {
            Image(systemName: store.isSupporter ? "heart.fill" : "cup.and.heat.waves.fill")
                .font(.system(size: iconSize * 0.46, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: store.isSupporter)
                .frame(width: iconSize, height: iconSize)
                .background(
                    LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: iconSize * 0.27, style: .continuous)
                )
                .shadow(color: .pink.opacity(0.35), radius: 8, y: 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: isCompact ? 2 : 3) {
                Text(store.isSupporter ? "support.thankYou" : "common.supportTheDeveloper")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(isCompact ? 1 : nil)
                    .minimumScaleFactor(0.85)
                Text(store.isSupporter ? "settings.support.supporterSubtitle" : "settings.support.subtitle")
                    .font(isCompact ? .footnote : .subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(isCompact ? 2 : nil)
                    .fixedSize(horizontal: false, vertical: !isCompact)
            }

            Spacer(minLength: 8)

            if !isCompact {
                DisclosureChevron()
            }
        }
        .padding(isCompact ? 12 : 16)
        .background {
            #if os(macOS)
            // A Mac list row isn't rounded, so the card has its own corners and border.
            let shape = RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
            shape
                .fill(Theme.Palette.elevated)
                .overlay(shape.fill(Self.wash))
                .overlay(shape.strokeBorder(Color.pink.opacity(0.35), lineWidth: 1))
            #else
            ConcentricRectangle()
                .fill(Theme.Palette.elevated)
                .overlay(ConcentricRectangle().fill(Self.wash))
                // `ConcentricRectangle` can't be inset, so the stroke is centred on the
                // edge: the row clips its outer half, leaving a 1 pt border that
                // follows the row's corners exactly.
                .overlay(ConcentricRectangle().stroke(Color.pink.opacity(0.35), lineWidth: 2))
            #endif
        }
        #if os(macOS)
        .contentShape(.rect(cornerRadius: Theme.Radius.row))
        #else
        .contentShape(ConcentricRectangle())
        #endif
        .animation(.snappy, value: store.isSupporter)
        // Loads the offers along with the subscription, so the Support sheet opens ready.
        .task { await store.load() }
    }
}

#if DEBUG
#Preview {
    List {
        SupportDeveloperCard()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        SupportDeveloperCard(isCompact: true)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }
    .environment(SupportStore(service: PreviewSupportService()))
}
#endif
