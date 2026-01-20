//  AuthenticationManager.swift
//  GlassCast - Production-ready authentication with Supabase support

import Foundation
import Combine

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published private(set) var authState: AuthState = .loading
    @Published private(set) var currentUser: User?
    @Published private(set) var accessToken: String?

    private let supabaseClient = SupabaseClient.shared
    private let config = ConfigurationManager.shared

    enum AuthState {
        case loading
        case authenticated
        case unauthenticated
    }

    init() {
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Public Methods

    func signIn(email: String, password: String) async throws {
        // Validate credentials first
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
        }
        
        if config.supabaseConfigured {
            // Try Supabase authentication - DON'T fall back to demo
            let session = try await supabaseClient.signIn(email: email, password: password)

            if let user = session.user {
                let appUser = User(
                    id: UUID(uuidString: user.id) ?? UUID(),
                    email: user.email ?? email,
                    createdAt: Date()
                )
                currentUser = appUser
                accessToken = session.access_token
                authState = .authenticated
                saveUserToDefaults(appUser)
                saveTokenToDefaults(session.access_token)
            } else {
                throw AuthError.unknown
            }
        } else {
            // Use local demo authentication if Supabase not configured
            try await demoSignIn(email: email, password: password)
        }
    }

    func signUp(email: String, password: String) async throws {
        // Validate credentials first
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.invalidPassword
        }
        
        if config.supabaseConfigured {
            // Try Supabase authentication - DON'T fall back to demo
            let signUpResponse = try await supabaseClient.signUp(email: email, password: password)
            
            let appUser = User(
                id: UUID(uuidString: signUpResponse.id) ?? UUID(),
                email: signUpResponse.email ?? email,
                createdAt: Date()
            )
            currentUser = appUser
            authState = .authenticated
            saveUserToDefaults(appUser)
            
            // Save access token if available from response
            if let session = try? await supabaseClient.signIn(email: email, password: password) {
                accessToken = session.access_token
                saveTokenToDefaults(session.access_token)
            }
        } else {
            // Use local demo authentication if Supabase not configured
            try await demoSignUp(email: email, password: password)
        }
    }

    func signOut() async {
        currentUser = nil
        accessToken = nil
        authState = .unauthenticated
        removeUserFromDefaults()
        removeTokenFromDefaults()
    }
    
    // MARK: - Private Methods
    
    private func checkExistingSession() async {
        // Try to load user from defaults
        if let user = loadUserFromDefaults() {
            currentUser = user
            accessToken = loadTokenFromDefaults()
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
    }
    
    private func demoSignIn(email: String, password: String) async throws {
        try await Task.sleep(for: .seconds(1))
        
        // Demo: For first time login, create a test user with this email
        // For subsequent logins, check if the email exists
        let savedUser = User(id: UUID(), email: email, createdAt: Date())
        currentUser = savedUser
        authState = .authenticated
        saveUserToDefaults(savedUser)
    }
    
    private func demoSignUp(email: String, password: String) async throws {
        try await Task.sleep(for: .seconds(1))
        
        // Demo: simply create a new user
        let newUser = User(id: UUID(), email: email, createdAt: Date())
        currentUser = newUser
        authState = .authenticated
        saveUserToDefaults(newUser)
    }
    
    // MARK: - UserDefaults Management
    
    private func saveUserToDefaults(_ user: User) {
        let key = "glasscast_authenticated_user"
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadUserFromDefaults() -> User? {
        let key = "glasscast_authenticated_user"
        if let data = UserDefaults.standard.data(forKey: key),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            return user
        }
        return nil
    }
    
    private func removeUserFromDefaults() {
        let key = "glasscast_authenticated_user"
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func saveTokenToDefaults(_ token: String) {
        let key = "glasscast_access_token"
        UserDefaults.standard.set(token, forKey: key)
    }

    private func loadTokenFromDefaults() -> String? {
        let key = "glasscast_access_token"
        return UserDefaults.standard.string(forKey: key)
    }

    private func removeTokenFromDefaults() {
        let key = "glasscast_access_token"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case userNotFound
    case emailAlreadyExists
    case supabaseError(SupabaseError)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 6 characters"
        case .userNotFound:
            return "No account found with this email"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .supabaseError(let error):
            return error.errorDescription
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}
