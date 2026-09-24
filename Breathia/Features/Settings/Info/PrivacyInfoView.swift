import SwiftUI

struct PrivacyInfoView: View {
    var body: some View {
        InfoPage(title: "common.privacy", sections: [
            .init(heading: "settings.info.yourDataStays", body: "settings.info.heartRateReadingsHRV"),
            .init(heading: "settings.info.bluetooth", body: "settings.info.bluetoothIsUsedSolely"),
            .init(heading: "settings.info.deletingData", body: "settings.info.swipeASession"),
        ])
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PrivacyInfoView()
    }
}
#endif
