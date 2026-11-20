import Foundation
import SwiftData
import Testing
@testable import Breathia

/// History saved by an earlier version opens unchanged in this one.
@MainActor
struct HistoryMigrationTests {
    private func temporaryStore() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "History.store")
    }

    /// Writes sessions the way version 1 of the store did, then closes it.
    private func saveVersion1(_ count: Int, at url: URL) throws -> [UUID] {
        let schema = Schema(versionedSchema: HistorySchemaV1.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration("History", schema: schema, url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        var ids: [UUID] = []
        for index in 0..<count {
            let id = UUID()
            ids.append(id)
            context.insert(HistorySchemaV1.SessionEntity(
                id: id,
                date: Date(timeIntervalSince1970: 1_000_000 + Double(index) * 3_600),
                techniqueID: "resonance",
                duration: 600,
                heartRateStart: 71, heartRateAverage: 64, heartRateEnd: 58,
                hrvMetric: "rmssd", hrvAverage: 48.5, hrvTrend: "increasing",
                heartRateTrace: [71, 68, 64, 60, 58],
                source: "iPhone"
            ))
        }
        // One session without a sensor, whose optional fields are all empty.
        context.insert(HistorySchemaV1.SessionEntity(
            id: UUID(), date: .now, techniqueID: "box", duration: 300,
            heartRateStart: nil, heartRateAverage: nil, heartRateEnd: nil,
            hrvMetric: nil, hrvAverage: nil, hrvTrend: nil,
            heartRateTrace: [], source: nil
        ))
        try context.save()
        return ids
    }

    @Test func keepsEverySessionFromVersion1() throws {
        let url = try temporaryStore()
        let ids = try saveVersion1(50, at: url)

        let repository = SwiftDataSessionRepository(container: try HistoryDatabase.makeContainer(url: url))
        let sessions = try repository.fetchAll()

        #expect(sessions.count == 51)
        let migrated = try #require(sessions.first { $0.id == ids[7] })
        #expect(migrated.techniqueID == "resonance")
        #expect(migrated.duration == 600)
        #expect(migrated.heartRate == HeartRateStats(start: 71, average: 64, end: 58))
        #expect(migrated.hrv == HRVStats(metric: .rmssd, average: 48.5, trend: .increasing))
        #expect(migrated.heartRateTrace == [71, 68, 64, 60, 58])
        #expect(migrated.source == .iPhone)
        // Recorded before timelines existed: none, and the report falls back to the trace.
        #expect(migrated.heartRateTimeline == nil)
        #expect(migrated.breathSwings == nil)
        #expect(migrated.heartRatePoints.count == 5)

        let withoutSensor = try #require(sessions.first { $0.techniqueID == "box" })
        #expect(withoutSensor.heartRate == nil)
        #expect(withoutSensor.hrv == nil)
    }

    @Test func aMigratedStoreTakesNewSessionsAndOpensAgain() throws {
        let url = try temporaryStore()
        _ = try saveVersion1(3, at: url)

        let new = PreviewData.sessions[0]
        do {
            let repository = SwiftDataSessionRepository(container: try HistoryDatabase.makeContainer(url: url))
            try repository.insert(new)
        }

        // Opening the already migrated store again changes nothing.
        let reopened = SwiftDataSessionRepository(container: try HistoryDatabase.makeContainer(url: url))
        let sessions = try reopened.fetchAll()
        #expect(sessions.count == 5)
        let stored = try #require(sessions.first { $0.id == new.id })
        #expect(stored.heartRateTimeline == new.heartRateTimeline)
        #expect(stored.breathSwings == new.breathSwings)
    }

    @Test func deletingWorksAfterTheMigration() throws {
        let url = try temporaryStore()
        let ids = try saveVersion1(3, at: url)

        let repository = SwiftDataSessionRepository(container: try HistoryDatabase.makeContainer(url: url))
        try repository.delete(sessionID: ids[1])
        #expect(try repository.fetchAll().count == 3)
        #expect(try !repository.fetchAll().contains { $0.id == ids[1] })
    }
}
