//
//  AuthenticationViewModel.swift
//  GlassCast
//
//  MVVM ViewModel for authentication
//

import Foundation
import Combine

@MainActor
final class AuthenticationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mode: AuthMode = .login

    // MARK: - Dependencies

    private let authManager: AuthenticationManager

    // MARK: - Types

    enum AuthMode {
        case login
        case signup

        var title: String {
            switch self {
            case .login: return "Welcome Back"
            case .signup: return "Create Account"
            }
        }

        var subtitle: String {
            switch self {
            case .login: return "Sign in to continue"
            case .signup: return "Join GlassCast today"
            }
        }

        var buttonTitle: String {
            switch self {
            case .login: return "Sign In"
            case .signup: return "Create Account"
            }
        }

        var togglePrompt: String {
            switch self {
            case .login: return "Don't have an account?"
            case .signup: return "Already have an account?"
            }
        }

        var toggleAction: String {
            switch self {
            case .login: return "Sign Up"
            case .signup: return "Sign In"
            }
        }
    }

    // MARK: - Initialization

    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        isValidEmail(email)
    }

    var canSubmit: Bool {
        isFormValid && !isLoading
    }

    // MARK: - Actions

    func submit() async {
        guard canSubmit else { return }

        clearError()
        isLoading = true

        do {
            switch mode {
            case .login:
                try await performLogin()
            case .signup:
                try await performSignup()
            }
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func toggleMode() {
        mode = mode == .login ? .signup : .login
        clearError()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func performLogin() async throws {
        try await authManager.signIn(email: email, password: password)
    }

    private func performSignup() async throws {
        try await authManager.signUp(email: email, password: password)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            errorMessage = authError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
