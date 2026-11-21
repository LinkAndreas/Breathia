import Foundation
import Testing
@testable import Breathia

struct VersionHistoryTests {
    @Test func releasesAreNewestFirst() {
        let versions = VersionHistory.releases.map(\.version)
        #expect(versions == versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending })
        #expect(Set(versions).count == versions.count)
    }

    @Test func everyReleaseHasNotes() {
        for release in VersionHistory.releases {
            #expect(!release.notes.isEmpty)
            let prefix = "versionHistory.\(release.version.replacingOccurrences(of: ".", with: "_")).note"
            #expect(release.notes.allSatisfy { $0.key.hasPrefix(prefix) })
        }
    }

    @Test func marksTheRunningVersion() {
        let release = VersionHistory.releases[0]
        #expect(release.isInstalled(runningVersion: release.version))
        #expect(!release.isInstalled(runningVersion: "0.1"))
    }

    @Test func dateIsTheMonthItCameOut() {
        let release = VersionHistory.releases[0]
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: release.date)
        #expect(components.year == release.year)
        #expect(components.month == release.month)
    }
}
