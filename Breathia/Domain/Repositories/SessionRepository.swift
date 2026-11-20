import Foundation

/// Where completed sessions are kept.
///
/// A domain contract: `SessionHistory` depends on it, never on how or where the
/// sessions are stored. Implementations live in Infrastructure —
/// `SwiftDataSessionRepository` on device, `InMemorySessionRepository` for
/// previews and tests.
protocol SessionRepository {
    /// All sessions, newest first.
    func fetchAll() throws -> [SessionRecord]
    /// Stores `session`. Does nothing if a session with the same id exists, so
    /// sessions delivered twice (e.g. from Apple Watch) are kept once.
    func insert(_ session: SessionRecord) throws
    func delete(sessionID: SessionRecord.ID) throws
    /// Removes every session.
    func deleteAll() throws
}
