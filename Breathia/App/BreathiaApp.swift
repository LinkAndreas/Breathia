import SwiftUI

@main
struct BreathiaApp: App {
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: dependencies)
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 820)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
