import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var mode: AuthMode = .login

    var body: some View {
        NavigationStack {
            Group {
                if let dashboardViewModel = appState.dashboardViewModel {
                    DashboardView(
                        viewModel: dashboardViewModel,
                        onLogout: {
                            appState.authViewModel.logout()
                            appState.refreshAfterAuth()
                        }
                    )
                } else {
                    AuthContainerView(
                        mode: $mode,
                        viewModel: appState.authViewModel,
                        onAuthenticated: {
                            appState.refreshAfterAuth()
                        }
                    )
                }
            }
        }
    }
}
