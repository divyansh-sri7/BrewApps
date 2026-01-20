//
//  ErrorHandler.swift
//  GlassCast
//

import Foundation

enum AppError: LocalizedError {
    case network(String)
    case authentication(String)
    case database(String)
    case validation(String)
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .network(let message):
            return message
        case .authentication(let message):
            return message
        case .database(let message):
            return message
        case .validation(let message):
            return message
        case .generic(let message):
            return message
        }
    }

    static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let weatherError = error as? WeatherError {
            return .network(weatherError.errorDescription ?? "Weather service error")
        }

        if let authError = error as? AuthError {
            return .authentication(authError.errorDescription ?? "Authentication error")
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .network("No internet connection")
            case NSURLErrorTimedOut:
                return .network("Request timed out")
            default:
                return .network("Network error occurred")
            }
        }

        return .generic(error.localizedDescription)
    }
}
