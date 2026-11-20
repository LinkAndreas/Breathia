import SwiftUI

/// The release's new features, as a sheet.
struct WhatsNewView: View {
    /// Shows where a feature can be tried; the sheet closes first.
    let onTry: (WhatsNew.Feature.Destination) -> Void
    let onDone: () -> Void
    /// Called once the sheet is on screen, so it isn't shown again.
    var onSeen: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                WhatsNewHeader()
                ForEach(WhatsNew.features) { feature in
                    WhatsNewFeatureRow(feature: feature, onTry: onTry)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryActionButton(title: "whatsNew.continue", action: onDone)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
                .frame(maxWidth: 560)
        }
        .background(Theme.Palette.background)
        .onAppear(perform: onSeen)
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 560, idealHeight: 600)
        #endif
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewView(onTry: { _ in }, onDone: {})
        }
}
#endif
