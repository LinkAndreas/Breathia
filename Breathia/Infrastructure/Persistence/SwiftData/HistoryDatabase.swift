import Foundation
import SwiftData

/// Opens the SwiftData store that holds History.
enum HistoryDatabase {
    /// History stays on this device: CloudKit sync is explicitly off, so adding an
    /// iCloud capability later can't silently start syncing it.
    ///
    /// - Parameter url: Where the store is; the app's default location when `nil`.
    ///   Tests open a store of their own here.
    static func makeContainer(isStoredInMemoryOnly: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: HistorySchemaV2.self)
        let configuration = if let url {
            ModelConfiguration("History", schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            ModelConfiguration(
                "History",
                schema: schema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: HistoryMigrationPlan.self,
            configurations: configuration
        )
    }
}
