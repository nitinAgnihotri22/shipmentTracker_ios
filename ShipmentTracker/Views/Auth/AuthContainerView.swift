import SwiftUI

enum AuthMode {
    case login
    case signup
}

struct AuthContainerView: View {
    @Binding var mode: AuthMode
    @ObservedObject var viewModel: AuthViewModel
    let onAuthenticated: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Logistics Ops Assistant")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Upload CSV + ask shipment questions")
                .foregroundStyle(.secondary)

            Picker("Authentication", selection: $mode) {
                Text("Login").tag(AuthMode.login)
                Text("Sign Up").tag(AuthMode.signup)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Authentication mode")

            if mode == .login {
                LoginView(viewModel: viewModel) {
                    onAuthenticated()
                }
            } else {
                SignUpView(viewModel: viewModel) {
                    onAuthenticated()
                }
            }
        }
        .padding()
        .onChange(of: mode) { _, _ in
            viewModel.clearError()
        }
    }
}
