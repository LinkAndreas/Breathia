import Foundation
import SwiftData

/// `SessionRepository` backed by SwiftData, stored locally on the device.
final class SwiftDataSessionRepository: SessionRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
        // Every change is saved explicitly, so a write either succeeds or throws.
        context.autosaveEnabled = false
    }

    func fetchAll() throws -> [SessionRecord] {
        let newestFirst = FetchDescriptor<SessionEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(newestFirst).map(\.record)
    }

    func insert(_ session: SessionRecord) throws {
        guard try !contains(session.id) else { return }
        context.insert(SessionEntity(record: session))
        try context.save()
    }

    func delete(sessionID: SessionRecord.ID) throws {
        try context.delete(model: SessionEntity.self, where: #Predicate<SessionEntity> { $0.id == sessionID })
        try context.save()
    }

    private func contains(_ id: SessionRecord.ID) throws -> Bool {
        var descriptor = FetchDescriptor<SessionEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetchCount(descriptor) > 0
    }
}
