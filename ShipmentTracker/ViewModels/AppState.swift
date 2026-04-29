import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    let environment = AppEnvironment()
    @Published var authViewModel: AuthViewModel
    @Published var dashboardViewModel: DashboardViewModel?

    init() {
        let auth = AuthViewModel(authService: environment.authService)
        self.authViewModel = auth
        if let user = auth.currentUser {
            self.dashboardViewModel = DashboardViewModel(environment: environment, user: user)
        }
    }

    func refreshAfterAuth() {
        if let user = authViewModel.currentUser {
            dashboardViewModel = DashboardViewModel(environment: environment, user: user)
        } else {
            dashboardViewModel?.clearInMemoryState()
            dashboardViewModel = nil
        }
    }
}
