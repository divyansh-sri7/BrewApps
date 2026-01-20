//
//  AuthService.swift
//  GlassCast
//
//  Created by Claude on 20/01/26.
//

import Foundation
import Combine

//enum AuthError: LocalizedError {
//    case invalidEmail
//    case invalidPassword
//    case userNotFound
//    case emailAlreadyExists
//    case unknown
//
//    var errorDescription: String? {
//        switch self {
//        case .invalidEmail:
//            return "Please enter a valid email address"
//        case .invalidPassword:
//            return "Password must be at least 6 characters"
//        case .userNotFound:
//            return "No account found with this email"
//        case .emailAlreadyExists:
//            return "An account with this email already exists"
//        case .unknown:
//            return "An unexpected error occurred"
//        }
//    }
//}

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false

    private let userDefaultsKey = "glasscast_user"

    init() {
        loadUser()
    }

    func signIn(email: String, password: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard isValidPassword(password) else {
            throw AuthError.invalidPassword
        }

        // Simulate network delay
        try await Task.sleep(for: .seconds(1))

        // Check if user exists in UserDefaults
        if let savedUser = loadUserFromDefaults(email: email) {
            currentUser = savedUser
            isAuthenticated = true
            saveUser(savedUser)
        } else {
            throw AuthError.userNotFound
        }
    }

    func signUp(email: String, password: String) async throws {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard isValidPassword(password) else {
            throw AuthError.invalidPassword
        }

        // Simulate network delay
        try await Task.sleep(for: .seconds(1))

        // Check if user already exists
        if loadUserFromDefaults(email: email) != nil {
            throw AuthError.emailAlreadyExists
        }

        let newUser = User(email: email)
        currentUser = newUser
        isAuthenticated = true
        saveUser(newUser)
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Private Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }

    private func loadUserFromDefaults(email: String) -> User? {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data),
           user.email == email {
            return user
        }
        return nil
    }
}
