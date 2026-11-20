import Foundation
import SwiftData

/// Opens the SwiftData store that holds History.
enum HistoryDatabase {
    /// History stays on this device: CloudKit sync is explicitly off, so adding an
    /// iCloud capability later can't silently start syncing it.
    static func makeContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: HistorySchemaV2.self)
        let configuration = ModelConfiguration(
            "History",
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: HistoryMigrationPlan.self,
            configurations: configuration
        )
    }
}
