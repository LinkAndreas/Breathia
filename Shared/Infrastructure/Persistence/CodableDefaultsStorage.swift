import Foundation

/// Stores one `Codable` value as JSON under a `UserDefaults` key.
struct CodableDefaultsStorage<Value: Codable> {
    let key: String
    let defaults: UserDefaults

    func load() -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
