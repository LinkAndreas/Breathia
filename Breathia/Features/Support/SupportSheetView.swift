import SwiftUI

/// Support the Developer as a sheet, opened from the card at the top of Settings.
struct SupportSheetView: View {
    let onClose: () -> Void

    #if os(macOS)
    /// Mac sheets put their buttons at the bottom.
    private static let closePlacement = ToolbarItemPlacement.confirmationAction
    #else
    private static let closePlacement = ToolbarItemPlacement.primaryAction
    #endif

    var body: some View {
        SupportView()
            .sheetTitle("common.supportTheDeveloper")
            .toolbar {
                ToolbarItem(placement: Self.closePlacement) {
                    // The system close button: an ✕ with the localized "Close" label.
                    Button(role: .close, action: onClose)
                }
            }
            #if os(macOS)
            // A Mac sheet takes its content's size, and a form has none of its own.
            .frame(minWidth: 480, idealWidth: 540, minHeight: 560, idealHeight: 720)
            #else
            // A centred form on iPad rather than a full-height page.
            .presentationSizing(.form)
            #endif
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack { SupportSheetView(onClose: {}) }
        }
        .environment(SupportStore(service: PreviewSupportService()))
        .environment(AppIconStore.preview())
}
#endif
