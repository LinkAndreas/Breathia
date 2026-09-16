import Foundation
import SwiftData

/// Version 1 of the on-device History store.
///
/// Never edit a shipped schema. When the stored shape changes, add
/// `HistorySchemaV2` with the new model and a migration stage to
/// `HistoryMigrationPlan`.
enum HistorySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SessionEntity.self]
    }

    /// The persisted form of a `SessionRecord`. Flat, optional scalar fields keep
    /// the schema easy to query and migrate; conversion to and from the domain
    /// type lives in `SessionEntity+Record.swift`.
    @Model
    final class SessionEntity {
        #Index<SessionEntity>([\.date])

        @Attribute(.unique) var id: UUID
        var date: Date
        var techniqueID: String
        var duration: TimeInterval

        var heartRateStart: Int?
        var heartRateAverage: Int?
        var heartRateEnd: Int?

        var hrvMetric: String?
        var hrvAverage: Double?
        var hrvTrend: String?

        var heartRateTrace: [Double]
        var source: String?

        init(
            id: UUID,
            date: Date,
            techniqueID: String,
            duration: TimeInterval,
            heartRateStart: Int?,
            heartRateAverage: Int?,
            heartRateEnd: Int?,
            hrvMetric: String?,
            hrvAverage: Double?,
            hrvTrend: String?,
            heartRateTrace: [Double],
            source: String?
        ) {
            self.id = id
            self.date = date
            self.techniqueID = techniqueID
            self.duration = duration
            self.heartRateStart = heartRateStart
            self.heartRateAverage = heartRateAverage
            self.heartRateEnd = heartRateEnd
            self.hrvMetric = hrvMetric
            self.hrvAverage = hrvAverage
            self.hrvTrend = hrvTrend
            self.heartRateTrace = heartRateTrace
            self.source = source
        }
    }
}

/// The current version of the persisted session.
typealias SessionEntity = HistorySchemaV1.SessionEntity

enum HistoryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HistorySchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
