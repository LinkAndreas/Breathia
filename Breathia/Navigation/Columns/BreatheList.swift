import SwiftUI

/// Breathe's technique list, wired to the navigator.
struct BreatheList: View {
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        BreatheHomeView(
            usesSelection: navigator.usesSplitLayout,
            selectedTechniqueID: navigator.selectedTechniqueID,
            onOpen: { navigator.techniqueID = $0 },
            onShowSensor: { navigator.showSensor() }
        )
        .environment(screens.heartRateMonitor)
    }
}
