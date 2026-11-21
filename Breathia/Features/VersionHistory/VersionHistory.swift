import Foundation

/// Breathia's App Store releases, newest first, with what each one brought — the
/// Version History page in Settings.
///
/// To add a release, put it at the top of `releases` with its version and the year
/// and month it came out, and give each of its notes a key in `Localizable.xcstrings`:
/// `versionHistory.<version>.note<n>`, with the version's dots as underscores
/// (`versionHistory.1_8_2.note1`), translated into every language the app supports.
/// Add the same release to `content/releases.js` on Breathia's website, which shows
/// these notes on its version history page, so both stay in sync.
enum VersionHistory {
    struct Release: Identifiable {
        /// The version as the App Store shows it, e.g. "1.8.2".
        let version: String
        let year: Int
        let month: Int
        let notes: [LocalizedStringResource]

        var id: String { version }

        /// The first day of the month it came out, for showing its month and year.
        var date: Date {
            Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month)) ?? .distantPast
        }

        /// Whether this is the version running now.
        func isInstalled(runningVersion: String = Bundle.main.shortVersion) -> Bool {
            version == runningVersion
        }
    }

    static let releases: [Release] = [
        Release(version: "1.8.2", year: 2026, month: 11, notes: [
            "versionHistory.1_8_2.note1",
            "versionHistory.1_8_2.note2",
            "versionHistory.1_8_2.note3",
            "versionHistory.1_8_2.note4",
            "versionHistory.1_8_2.note5",
            "versionHistory.1_8_2.note6",
            "versionHistory.1_8_2.note7",
        ]),
        Release(version: "1.5.1", year: 2026, month: 11, notes: [
            "versionHistory.1_5_1.note1",
            "versionHistory.1_5_1.note2",
            "versionHistory.1_5_1.note3",
        ]),
        Release(version: "1.4.8", year: 2026, month: 10, notes: [
            "versionHistory.1_4_8.note1",
            "versionHistory.1_4_8.note2",
            "versionHistory.1_4_8.note3",
        ]),
    ]
}
