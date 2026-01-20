//
//  APIEndpoint.swift
//  GlassCast
//
//  API endpoint definitions
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension APIEndpoint {
    var url: URL? {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        return components?.url
    }

    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
}
