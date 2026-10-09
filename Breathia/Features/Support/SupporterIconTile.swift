import SwiftUI

/// One icon in the supporter icon picker: its preview, its name, and a ring when it's the app's icon.
struct SupporterIconTile: View {
    let icon: SupporterIcon
    let isSelected: Bool
    let isLocked: Bool
    let lockedTapCount: Int
    let action: () -> Void

    private static let size: CGFloat = 60
    /// The Home Screen's corner shape, scaled to the preview.
    private static let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(icon.previewImageName)
                    .resizable()
                    .frame(width: Self.size, height: Self.size)
                    .clipShape(Self.shape)
                    .overlay {
                        Self.shape.strokeBorder(.separator, lineWidth: 0.5)
                    }
                    .padding(4)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: Self.size * 0.225 + 4, style: .continuous)
                                .strokeBorder(.tint, lineWidth: 2.5)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(.black.opacity(0.55), in: .circle)
                                .symbolEffect(.bounce, value: lockedTapCount)
                        }
                    }

                Text(icon.title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        // Plain, so each icon is its own button rather than the whole row.
        .buttonStyle(.plain)
        .accessibilityLabel(Text(icon.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLocked ? Text("support.includedWithRecurringSupport") : Text(verbatim: ""))
    }
}

#if DEBUG
#Preview {
    HStack {
        SupporterIconTile(icon: .classic, isSelected: true, isLocked: false, lockedTapCount: 0) {}
        SupporterIconTile(icon: .ember, isSelected: false, isLocked: true, lockedTapCount: 0) {}
    }
    .padding()
}
#endif
