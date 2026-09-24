import Foundation

extension Technique {
    /// Whether the technique's name, purpose, summary, category, or uses mention `query`.
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return ([name, summary, purpose, category.title] + bestFor)
            .contains { $0.localizedStandardContains(query) }
    }
}
