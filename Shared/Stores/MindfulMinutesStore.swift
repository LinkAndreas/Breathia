import Foundation
import Observation
import OSLog

/// Apple Health access for mindful minutes, as the screens see it, and saving
/// sessions there. HealthKit stays behind `MindfulMinutesService`.
@Observable
final class MindfulMinutesStore {
    private(set) var access: HealthAccess

    @ObservationIgnored private let service: MindfulMinutesService
    @ObservationIgnored private let logger = Logger(subsystem: "Breathia", category: "Health")

    init(service: MindfulMinutesService) {
        self.service = service
        self.access = service.access
    }

    /// `false` on devices without Health, such as some iPads.
    var isAvailable: Bool { access != .unavailable }

    var isAllowed: Bool { access == .allowed }

    var isDenied: Bool { access == .denied }

    /// Re-reads access, e.g. after the user changed it in the Health app.
    func refreshAuthorizationStatus() {
        access = service.access
    }

    /// Shows the Health permission sheet if the user hasn't decided yet.
    /// Returns whether saving mindful minutes is allowed.
    @discardableResult
    func requestAuthorization() async -> Bool {
        access = await service.requestAccess()
        return isAllowed
    }

    /// Saves `session` when access was granted. Never asks for access itself —
    /// that only happens when the user turns the feature on, never mid-flow.
    func save(_ session: SessionRecord) async {
        refreshAuthorizationStatus()
        guard isAllowed else { return }
        do {
            try await service.save(session)
        } catch {
            logger.error("Saving mindful minutes failed: \(String(describing: error), privacy: .public)")
        }
    }
}
