import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .accessibilityLabel("Login email")

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Login password")

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Error \(errorMessage)")
            }

            Button("Login") {
                viewModel.login()
                if viewModel.currentUser != nil {
                    onSuccess()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Login button")
        }
    }
}
