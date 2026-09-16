import Foundation

enum HRVMetric: String, Codable, CaseIterable, Identifiable {
    case rmssd, sdnn

    var id: Self { self }
    /// The metric's abbreviation, which is the same in every language.
    var title: String { rawValue.uppercased() }

    func value(from hrv: HRV) -> Double {
        switch self {
        case .rmssd: hrv.rmssd
        case .sdnn: hrv.sdnn
        }
    }
}

enum FeedbackSensitivity: String, Codable, CaseIterable, Identifiable {
    case low, balanced, high

    var id: Self { self }

    var title: String {
        switch self {
        case .low: String(localized: "settings.option.low", comment: "Feedback sensitivity")
        case .balanced: String(localized: "settings.option.balanced", comment: "Feedback sensitivity")
        case .high: String(localized: "settings.option.high", comment: "Feedback sensitivity")
        }
    }

    /// Scales how much data and how large a change live feedback waits for.
    var multiplier: Double {
        switch self {
        case .low: 1.5
        case .balanced: 1
        case .high: 0.6
        }
    }
}

enum Appearance: String, Codable, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: String(localized: "settings.option.system", comment: "Appearance option")
        case .light: String(localized: "settings.option.light", comment: "Appearance option")
        case .dark: String(localized: "settings.option.dark", comment: "Appearance option")
        }
    }
}

struct AppSettings: Codable, Equatable {
    var hapticsEnabled = true
    var soundEnabled = true
    var countdownEnabled = true
    var hrvMetric: HRVMetric = .rmssd
    var feedbackSensitivity: FeedbackSensitivity = .balanced
    var appearance: Appearance = .system
    var hasCompletedOnboarding = false
    /// Save each finished session to Apple Health as mindful minutes. Off until the
    /// user turns it on in onboarding or Settings — which is also when Health access
    /// is requested, never at the end of a session.
    var savesMindfulMinutes = false
}

extension AppSettings {
    /// Decodes field by field, falling back to the default for any key that's
    /// missing — so settings saved by an older version (or sent by an older watch
    /// or phone) keep their values when a new setting is added, instead of the
    /// whole struct failing to decode and resetting.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()

        func value<T: Decodable>(_ key: CodingKeys, default fallback: T) throws -> T {
            try container.decodeIfPresent(T.self, forKey: key) ?? fallback
        }

        self.init()
        hapticsEnabled = try value(.hapticsEnabled, default: defaults.hapticsEnabled)
        soundEnabled = try value(.soundEnabled, default: defaults.soundEnabled)
        countdownEnabled = try value(.countdownEnabled, default: defaults.countdownEnabled)
        hrvMetric = try value(.hrvMetric, default: defaults.hrvMetric)
        feedbackSensitivity = try value(.feedbackSensitivity, default: defaults.feedbackSensitivity)
        appearance = try value(.appearance, default: defaults.appearance)
        hasCompletedOnboarding = try value(.hasCompletedOnboarding, default: defaults.hasCompletedOnboarding)
        savesMindfulMinutes = try value(.savesMindfulMinutes, default: defaults.savesMindfulMinutes)
    }
}
