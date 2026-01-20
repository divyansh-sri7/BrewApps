//
//  NetworkManager.swift
//  GlassCast
//
//  Core networking layer
//

import Foundation

protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()

    private init() {}

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.httpBody = endpoint.body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
