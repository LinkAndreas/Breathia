import NavigationKit
import Testing
@testable import Breathia

@MainActor
struct NavigationTests {
    @Test func everyRouteHasAScreen() {
        let registry = RouteRegistry([AppDependencies.preview().routes])

        #expect(registry.missingViews(for: AppRouteTypes.all).isEmpty)
    }
}
