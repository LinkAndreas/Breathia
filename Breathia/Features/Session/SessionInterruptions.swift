import SwiftUI
#if os(macOS)
import AppKit
#endif

extension View {
    /// Reports when a session on screen can no longer be followed, and when it can be
    /// again.
    ///
    /// - iPhone and iPad: when the app goes to the background — the device locks, or
    ///   the user goes Home or to another app. Not for Control Center, Notification
    ///   Center, or Siri, which only make the app briefly inactive.
    /// - Mac: when the session's window is minimized or hidden, or the screen locks or
    ///   sleeps. Switching to another app is not an interruption: the session keeps
    ///   playing its cues, as Mac multitasking expects.
    func sessionInterruptions(onInterrupt: @escaping () -> Void, onReturn: @escaping () -> Void) -> some View {
        modifier(SessionInterruptions(onInterrupt: onInterrupt, onReturn: onReturn))
    }
}

private struct SessionInterruptions: ViewModifier {
    let onInterrupt: () -> Void
    let onReturn: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background: onInterrupt()
                case .active: onReturn()
                default: break
                }
            }
            #if os(macOS)
            .task {
                await observeScreenLock()
            }
            #endif
    }

    #if os(macOS)
    /// The screen locking or sleeping interrupts; unlocking or waking returns.
    private func observeScreenLock() async {
        let workspace = NSWorkspace.shared.notificationCenter
        let distributed = DistributedNotificationCenter.default()
        await withTaskGroup(of: Void.self) { group in
            for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
                group.addTask { for await _ in workspace.notifications(named: name) { await onInterrupt() } }
            }
            for name in [NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
                group.addTask { for await _ in workspace.notifications(named: name) { await onReturn() } }
            }
            group.addTask {
                for await _ in distributed.notifications(named: .init("com.apple.screenIsLocked")) { await onInterrupt() }
            }
            group.addTask {
                for await _ in distributed.notifications(named: .init("com.apple.screenIsUnlocked")) { await onReturn() }
            }
        }
    }
    #endif
}
