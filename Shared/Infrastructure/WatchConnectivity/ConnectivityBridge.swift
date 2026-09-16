#if canImport(WatchConnectivity)
import Foundation
import OSLog
import WatchConnectivity

/// Keys of the payloads exchanged between the iPhone and Apple Watch apps.
enum SyncKey {
    /// A finished `SessionRecord`, watch → iPhone, queued for guaranteed delivery.
    static let session = "session"
    /// The current `AppSettings`, iPhone → watch, latest value wins.
    static let settings = "settings"
}

/// Thin `WCSession` wrapper shared by the iPhone and watch apps. Delegate
/// callbacks arrive on a background queue, so payloads are handed to the main
/// actor as raw `Data` and decoded there by the owner.
nonisolated final class ConnectivityBridge: NSObject, WCSessionDelegate, @unchecked Sendable {
    typealias ActivationHandler = @MainActor @Sendable () -> Void
    typealias ReceiveHandler = @MainActor @Sendable (_ key: String, _ data: Data) -> Void

    private let onActivate: ActivationHandler
    private let onReceive: ReceiveHandler
    private let logger = Logger(subsystem: "Breathia", category: "WatchConnectivity")

    private let lock = NSLock()
    /// Transfers requested before the session finished activating; sent on activation.
    private var pendingTransfers: [[String: Any]] = []

    init(onActivate: @escaping ActivationHandler, onReceive: @escaping ReceiveHandler) {
        self.onActivate = onActivate
        self.onReceive = onReceive
        super.init()
    }

    private var session: WCSession? {
        WCSession.isSupported() ? .default : nil
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Delivers a payload the receiver must not miss. Kept until the session is
    /// activated, so nothing is lost when it's requested early.
    func transfer(_ data: Data, forKey key: String) {
        guard let session else { return }
        let payload: [String: Any] = [key: data]
        let isActivated = lock.withLock {
            guard session.activationState == .activated else {
                pendingTransfers.append(payload)
                return false
            }
            return true
        }
        if isActivated {
            deliver(payload, over: session)
        } else {
            logger.info("Session not activated yet; holding \(key, privacy: .public) until it is")
        }
    }

    func updateContext(_ data: Data, forKey key: String) {
        guard let session, session.activationState == .activated else { return }
        do {
            try session.updateApplicationContext([key: data])
        } catch {
            logger.error("Updating the application context failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Sends right away when the counterpart is reachable, and always queues a
    /// background transfer too, which the system delivers even if the counterpart
    /// app isn't running. Receivers must therefore tolerate duplicates.
    private func deliver(_ payload: [String: Any], over session: WCSession) {
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [logger] error in
                logger.info("Live message failed, relying on background transfer: \(String(describing: error), privacy: .public)")
            }
        }
        session.transferUserInfo(payload)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        guard activationState == .activated else {
            logger.error("Activation failed (state \(activationState.rawValue)): \(String(describing: error), privacy: .public)")
            return
        }
        #if os(watchOS)
        logger.info("Activated; companion app installed: \(session.isCompanionAppInstalled)")
        #else
        logger.info("Activated; paired: \(session.isPaired), watch app installed: \(session.isWatchAppInstalled)")
        #endif

        let pending = lock.withLock {
            defer { pendingTransfers.removeAll() }
            return pendingTransfers
        }
        for payload in pending {
            deliver(payload, over: session)
        }

        forward(session.receivedApplicationContext)
        let onActivate = onActivate
        Task { @MainActor in onActivate() }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        forward(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        forward(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        forward(applicationContext)
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: (any Error)?) {
        guard let error else { return }
        logger.error("Background transfer failed: \(String(describing: error), privacy: .public)")
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // The user switched watches; start talking to the new one.
        session.activate()
    }
    #endif

    private func forward(_ payload: [String: Any]) {
        let onReceive = onReceive
        for (key, value) in payload {
            guard let data = value as? Data else { continue }
            Task { @MainActor in onReceive(key, data) }
        }
    }
}
#endif
