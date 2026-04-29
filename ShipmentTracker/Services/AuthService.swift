import CryptoKit
import Foundation

protocol AuthServicing {
    var currentSession: Session? { get }
    func allUsers() -> [UserAccount]
    func signUp(fullName: String, email: String, password: String) throws -> UserAccount
    func login(email: String, password: String) throws -> UserAccount
    func logout()
}

final class AuthService: AuthServicing {
    private let usersKey = "logistics.users"
    private let sessionKey = "logistics.session"
    private let store: LocalStore

    private(set) var currentSession: Session?

    init(store: LocalStore = LocalStore()) {
        self.store = store
        self.currentSession = store.load(Session.self, forKey: sessionKey)
    }

    func allUsers() -> [UserAccount] {
        store.load([UserAccount].self, forKey: usersKey) ?? []
    }

    func signUp(fullName: String, email: String, password: String) throws -> UserAccount {
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty, !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            throw AuthError.requiredFields
        }

        let users = allUsers()
        if users.contains(where: { $0.email == cleanEmail }) {
            throw AuthError.userAlreadyExists
        }

        let account = UserAccount(
            id: UUID(),
            fullName: cleanName,
            email: cleanEmail,
            passwordHash: hash(cleanPassword),
            createdAt: Date()
        )

        try store.save(users + [account], forKey: usersKey)
        try store.save(Session(email: cleanEmail), forKey: sessionKey)
        currentSession = Session(email: cleanEmail)
        return account
    }

    func login(email: String, password: String) throws -> UserAccount {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            throw AuthError.requiredFields
        }

        guard let user = allUsers().first(where: { $0.email == cleanEmail }),
              user.passwordHash == hash(cleanPassword) else {
            throw AuthError.invalidCredentials
        }

        let session = Session(email: cleanEmail)
        try store.save(session, forKey: sessionKey)
        currentSession = session
        return user
    }

    func logout() {
        currentSession = nil
        store.remove(forKey: sessionKey)
    }

    private func hash(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
