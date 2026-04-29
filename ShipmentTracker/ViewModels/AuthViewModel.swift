import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var currentUser: UserAccount?

    private let authService: AuthServicing

    init(authService: AuthServicing) {
        self.authService = authService
        restoreSession()
    }

    func restoreSession() {
        guard let session = authService.currentSession else {
            currentUser = nil
            return
        }
        currentUser = authService.allUsers().first(where: { $0.email == session.email })
    }

    func signUp() {
        do {
            let user = try authService.signUp(fullName: fullName, email: email, password: password)
            currentUser = user
            errorMessage = nil
            clearFields()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func login() {
        do {
            let user = try authService.login(email: email, password: password)
            currentUser = user
            errorMessage = nil
            clearFields()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func logout() {
        authService.logout()
        currentUser = nil
        clearFields()
    }

    func clearError() {
        errorMessage = nil
    }

    private func clearFields() {
        fullName = ""
        email = ""
        password = ""
    }
}
