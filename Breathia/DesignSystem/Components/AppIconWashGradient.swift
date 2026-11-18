import SwiftUI

/// One icon's wash: its sky at the top, fading through its glow.
struct AppIconWashGradient: View {
    let palette: AppIconVariant.Palette

    var body: some View {
        let locations = AppIconVariant.Palette.locations
        LinearGradient(
            stops: [
                .init(color: palette.sky, location: locations[0]),
                .init(color: palette.glow, location: locations[1]),
                // The glow, faded out, rather than `.clear`, which would fade through black.
                .init(color: palette.glow.opacity(0), location: locations[2]),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#if DEBUG
#Preview {
    AppIconWashGradient(palette: AppIconVariant.lagoon.palette)
}
#endif
