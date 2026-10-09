import SwiftUI

/// The page background in the app icon's colors: the grouped background with a soft wash of
/// the icon's sky at the top, fading through its glow. Changing the icon crossfades the wash.
struct AppIconWash: View {
    @Environment(AppIconStore.self) private var iconStore

    var body: some View {
        ZStack {
            Theme.Palette.background

            // Each icon's wash is its own view, so changing the icon crossfades between them.
            AppIconWashGradient(palette: iconStore.current.palette)
                .id(iconStore.current)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.6), value: iconStore.current)
        .ignoresSafeArea()
    }
}

#if DEBUG
#Preview {
    AppIconWash()
        .environment(AppIconStore.preview(.ember))
}
#endif
