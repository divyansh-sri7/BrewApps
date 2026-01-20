//
//  NetworkError.swift
//  GlassCast
//
//  Network error types
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case networkFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode: \(error.localizedDescription)"
        case .networkFailed(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
