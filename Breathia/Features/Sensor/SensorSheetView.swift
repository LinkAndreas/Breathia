import SwiftUI
#if os(iOS)
import UIKit
#endif

/// The sensor connection flow as a sheet: scans on open and closes itself once
/// the sensor connects.
struct SensorSheetView: View {
    let onDone: () -> Void

    @Environment(HeartRateMonitor.self) private var monitor
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        SensorConnectionView()
            .sheetTitle(verbatim: SettingsPage.sensor.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done", action: onDone)
                }
            }
            #if os(iOS)
            // By device, not size class: inside an iPad sheet the size class is compact too.
            .modifier(SheetHeight(detent: $detent, isPhone: UIDevice.current.userInterfaceIdiom == .phone))
            #endif
            .onAppear {
                if needsFullHeight { detent = .large }
            }
            .onChange(of: needsFullHeight) { _, needsFullHeight in
                if needsFullHeight { detent = .large }
            }
            .onChange(of: monitor.isConnected) { wasConnected, isConnected in
                if !wasConnected && isConnected { onDone() }
            }
            #if os(macOS)
            // A Mac sheet takes its content's size, and a form has none of its own.
            .frame(minWidth: 460, idealWidth: 500, minHeight: 380, idealHeight: 440)
            #endif
    }

    /// The permission explanation and the access-denied screen need the whole
    /// height; searching and the list of sensors fit the half-height sheet.
    private var needsFullHeight: Bool {
        switch monitor.status {
        case .needsPermission, .denied: true
        default: false
        }
    }
}

#if os(iOS)
/// Half or full height on iPhone. On iPad a centred form instead: any detent turns an
/// iPad sheet into one docked to the bottom edge.
private struct SheetHeight: ViewModifier {
    @Binding var detent: PresentationDetent
    let isPhone: Bool

    func body(content: Content) -> some View {
        if isPhone {
            content.presentationDetents([.medium, .large], selection: $detent)
        } else {
            content.presentationSizing(.form)
        }
    }
}
#endif

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack { SensorSheetView(onDone: {}) }
        }
        .environment(PreviewStores.heartRateMonitor())
}
#endif
