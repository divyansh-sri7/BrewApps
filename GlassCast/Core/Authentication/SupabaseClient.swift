//
//  SupabaseClient.swift
//  GlassCast
//
//  Supabase client for authentication and API calls
//

import Foundation

@MainActor
final class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let session = URLSession.shared
    private let config = ConfigurationManager.shared
    
    private init() {}
    
    // MARK: - Authentication Requests
    
    func signUp(email: String, password: String) async throws -> SupabaseUser {
        guard let baseURL = config.supabaseURL else {
            throw SupabaseError.invalidURL
        }
        
        // Build correct URL: https://zzvsoxkewzxoiewrbkli.supabase.co/auth/v1/signup
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.path = "/auth/v1/signup"
        
        guard let url = urlComponents?.url else {
            throw SupabaseError.invalidURL
        }
        
        let body = SignUpRequest(email: email, password: password)
        let data = try JSONEncoder().encode(body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = data
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        // Debug: Print response for troubleshooting
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("Supabase SignUp Response (\(httpResponse.statusCode)): \(responseString)")
            print("URL Used: \(url.absoluteString)")
        }
        
        // Handle specific status codes
        switch httpResponse.statusCode {
        case 200...299:
            let authResponse = try JSONDecoder().decode(SignUpResponse.self, from: responseData)
            return authResponse.user
            
        case 400:
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: responseData) {
                print("Supabase Error: \(errorResponse.error ?? "Unknown") - \(errorResponse.error_description ?? "")")
                if errorResponse.error_description?.lowercased().contains("already") == true {
                    throw SupabaseError.emailAlreadyExists
                }
            }
            throw SupabaseError.invalidRequest
            
        default:
            throw SupabaseError.invalidResponse
        }
    }
    
    func signIn(email: String, password: String) async throws -> SupabaseAuthSession {
        guard let baseURL = config.supabaseURL else {
            throw SupabaseError.invalidURL
        }
        
        // Build correct URL: https://zzvsoxkewzxoiewrbkli.supabase.co/auth/v1/token?grant_type=password
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.path = "/auth/v1/token"
        urlComponents?.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        
        guard let url = urlComponents?.url else {
            throw SupabaseError.invalidURL
        }
        
        let body = SignInRequest(email: email, password: password, grant_type: "password")
        let data = try JSONEncoder().encode(body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = data
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        // Debug: Print response for troubleshooting
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("Supabase SignIn Response (\(httpResponse.statusCode)): \(responseString)")
            print("URL Used: \(url.absoluteString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(SupabaseAuthSession.self, from: responseData)
            
        case 401, 400:
            // Try to parse error
            if let errorResponse = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: responseData) {
                print("Supabase Auth Error: \(errorResponse.error ?? "Unknown") - \(errorResponse.error_description ?? "")")
            }
            throw SupabaseError.invalidCredentials
            
        default:
            throw SupabaseError.invalidResponse
        }
    }
    
    // MARK: - Database Operations

    func fetch(table: String, accessToken: String? = nil) async throws -> Data {
        guard let url = makeRestURL(table: table) else {
            throw SupabaseError.invalidURL
        }

        print("📡 Fetching from table: \(table)")
        print("📡 URL: \(url.absoluteString)")
        print("📡 Has access token: \(accessToken != nil)")

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("📡 Using user access token")
        } else {
            request.setValue("Bearer \(config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            print("📡 Using anon key")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw SupabaseError.invalidResponse
        }

        print("📡 Response status: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response data: \(responseString)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            throw SupabaseError.invalidResponse
        }

        return data
    }

    func insert(table: String, values: [String: Any], accessToken: String? = nil) async throws {
        guard let url = makeRestURL(table: table) else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: values)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("Supabase Insert Response (\(httpResponse.statusCode)): \(responseString)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }
    }

    func delete(table: String, id: String, accessToken: String? = nil) async throws {
        guard var url = makeRestURL(table: table) else {
            throw SupabaseError.invalidURL
        }

        url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(id)")])

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }
    }

    // MARK: - Helper Methods

    private func makeRestURL(table: String) -> URL? {
        guard let baseURL = config.supabaseURL else { return nil }
        return baseURL.appendingPathComponent("rest/v1").appendingPathComponent(table)
    }
}

// MARK: - Models

struct SignUpRequest: Codable {
    let email: String
    let password: String
}

struct SignUpResponse: Codable {
    let user: SupabaseUser
    let session: SupabaseAuthSession?
}

struct SignInRequest: Codable {
    let email: String
    let password: String
    let grant_type: String
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let email_confirmed_at: String?
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, email_confirmed_at, created_at
    }
}

struct SupabaseAuthSession: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let expires_at: Int?
    let refresh_token: String?
    let user: SupabaseUser?
}

struct SupabaseErrorResponse: Codable {
    let error: String?
    let error_description: String?
    let error_uri: String?
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidRequest
    case invalidCredentials
    case emailAlreadyExists
    case networkError(Error)
    case decodingError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Supabase URL configuration"
        case .invalidResponse:
            return "Invalid response from Supabase"
        case .invalidRequest:
            return "Invalid request to Supabase"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}
