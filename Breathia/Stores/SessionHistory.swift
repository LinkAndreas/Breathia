import Foundation
import Observation
import OSLog

/// The list of completed sessions, newest first. Reads and writes go through a
/// `SessionRepository`, so this store knows nothing about how History is stored.
@Observable
final class SessionHistory {
    private(set) var sessions: [SessionRecord] = []

    @ObservationIgnored private let repository: SessionRepository
    @ObservationIgnored private let logger = Logger(subsystem: "Breathia", category: "History")

    init(repository: SessionRepository) {
        self.repository = repository
        reload()
    }

    func reload() {
        do {
            sessions = try repository.fetchAll()
        } catch {
            logger.error("Loading history failed: \(String(describing: error), privacy: .public)")
        }
    }

    func session(withID id: SessionRecord.ID) -> SessionRecord? {
        sessions.first { $0.id == id }
    }

    /// Stores a finished session and inserts it in date order. Duplicates are
    /// ignored, since sessions from Apple Watch can arrive late or more than once.
    func record(_ session: SessionRecord) {
        guard !sessions.contains(where: { $0.id == session.id }) else { return }
        do {
            try repository.insert(session)
        } catch {
            logger.error("Saving a session failed: \(String(describing: error), privacy: .public)")
            return
        }
        let index = sessions.firstIndex { $0.date < session.date } ?? sessions.endIndex
        sessions.insert(session, at: index)
    }

    func delete(_ session: SessionRecord) {
        do {
            try repository.delete(sessionID: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            logger.error("Deleting a session failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Removes every session from History. Mindful minutes already saved to Apple
    /// Health stay there; they belong to Health.
    func deleteAll() {
        do {
            try repository.deleteAll()
            sessions.removeAll()
        } catch {
            logger.error("Deleting all sessions failed: \(String(describing: error), privacy: .public)")
            // Show what's actually left, in case some were removed before the failure.
            reload()
        }
    }
}
