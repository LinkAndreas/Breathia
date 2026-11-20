import SwiftUI

/// A settings icon: a white symbol on a softly lit tile in a `SettingsTone`.
///
/// The tile is a continuous squircle like the system's, but lit from above with
/// a fine edge of light along its top and a hairline rim, so it reads as an
/// object rather than a flat swatch — in the same quiet tones as the techniques'
/// orbs.
struct SettingsIcon: View {
    let systemImage: String
    let tone: SettingsTone

    #if os(macOS)
    private static let side: CGFloat = 22
    #else
    private static let side: CGFloat = 29
    #endif

    /// The box a symbol fits in, as a share of the tile: about a fifth of the
    /// tile stays clear on every side, as on the system's icons.
    private static let symbolWidth: CGFloat = 0.64
    private static let symbolHeight: CGFloat = 0.58

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Self.side * 0.26, style: .continuous)
    }

    var body: some View {
        Image(systemName: systemImage)
            .resizable()
            .scaledToFit()
            .fontWeight(.medium)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.white)
            // Every symbol fits the same inner box, so wide ones like a speaker
            // with three waves keep as much room to the edge as narrow ones.
            .frame(width: Self.side * Self.symbolWidth, height: Self.side * Self.symbolHeight)
            // A breath of depth under the symbol, so it sits on the tile.
            .shadow(color: .black.opacity(0.12), radius: 0.5, y: 0.5)
            .frame(width: Self.side, height: Self.side)
            .background {
                shape.fill(LinearGradient(colors: [tone.top, tone.bottom], startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                // Light catching the top edge, fading out halfway down.
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.06), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
            }
            .overlay {
                // A hairline rim, so a light tile still holds its edge on white.
                shape.strokeBorder(.black.opacity(0.08), lineWidth: 0.5)
            }
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    let tones: [(String, SettingsTone)] = [
        ("antenna.radiowaves.left.and.right", .heart), ("hand.tap.fill", .haptics), ("timer", .countdown),
        ("speaker.wave.2.fill", .soundCues), ("music.note", .cueSound), ("waveform.path.ecg", .hrvMetric),
        ("heart.fill", .health), ("trash.fill", .destructive), ("star.fill", .rate), ("info", .information),
    ]
    HStack(spacing: 10) {
        ForEach(tones, id: \.0) { symbol, tone in
            SettingsIcon(systemImage: symbol, tone: tone)
        }
    }
    .padding()
}
#endif
