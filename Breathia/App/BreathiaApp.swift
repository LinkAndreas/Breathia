import SwiftUI

@main
struct BreathiaApp: App {
    @State private var dependencies = Self.makeDependencies()

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: dependencies)
                #if DEBUG
                .task { await dependencies.navigator.showForScreenshots() }
                #if os(macOS)
                .task { await ScreenshotScreen.sizeWindow() }
                #endif
                #endif
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .defaultSize(Self.windowSize)
        .commands {
            SidebarCommands()
        }
        #endif
    }

    #if os(macOS)
    private static var windowSize: CGSize {
        #if DEBUG
        if ScreenshotScreen.requested != nil {
            return ScreenshotScreen.windowSize
        }
        #endif
        return CGSize(width: 1280, height: 820)
    }
    #endif

    private static func makeDependencies() -> AppDependencies {
        #if DEBUG
        if ScreenshotScreen.requested != nil {
            return .screenshots()
        }
        #endif
        return .live()
    }
}
