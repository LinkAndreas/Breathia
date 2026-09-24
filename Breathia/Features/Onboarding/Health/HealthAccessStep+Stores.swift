import Foundation

extension HealthAccessStep {
    /// The onboarding's Apple Health step, or `nil` where Health isn't available.
    /// The user's answer becomes the "Save Mindful Minutes" setting.
    static func make(mindfulMinutes: MindfulMinutesStore, settingsStore: SettingsStore) -> HealthAccessStep? {
        guard mindfulMinutes.isAvailable else { return nil }
        mindfulMinutes.refreshAuthorizationStatus()
        let alreadyAllowed = settingsStore.settings.savesMindfulMinutes && mindfulMinutes.isAllowed
        return HealthAccessStep(
            initialState: alreadyAllowed ? .allowed : .undecided,
            requestAccess: {
                let isAllowed = await mindfulMinutes.requestAuthorization()
                settingsStore.settings.savesMindfulMinutes = isAllowed
                return isAllowed
            },
            decline: {
                settingsStore.settings.savesMindfulMinutes = false
            }
        )
    }
}
