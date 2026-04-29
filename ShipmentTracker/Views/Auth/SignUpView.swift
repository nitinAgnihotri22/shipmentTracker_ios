import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("Full Name", text: $viewModel.fullName)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Sign up full name")

            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .accessibilityLabel("Sign up email")

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Sign up password")

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Error \(errorMessage)")
            }

            Button("Sign Up") {
                viewModel.signUp()
                if viewModel.currentUser != nil {
                    onSuccess()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Sign up button")
        }
    }
}
