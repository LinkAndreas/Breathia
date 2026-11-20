import SwiftUI

/// A question asked over the whole app, as an alert. `AppNavigator.ask(_:)`
/// presents it and returns the chosen action.
struct AppDialog: Identifiable {
    struct Action: Identifiable {
        typealias ID = String

        let id: ID
        let title: LocalizedStringResource
        let role: ButtonRole?

        init(_ title: LocalizedStringResource, id: ID, role: ButtonRole? = nil) {
            self.title = title
            self.id = id
            self.role = role
        }
    }

    let id = UUID()
    let title: LocalizedStringResource
    let message: LocalizedStringResource?
    let actions: [Action]

    init(_ title: LocalizedStringResource, message: LocalizedStringResource? = nil, actions: [Action]) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}
