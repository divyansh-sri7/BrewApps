//
//  City.swift
//  GlassCast
//

import Foundation

struct WeatherCity: Identifiable, Codable {
    let id: UUID
    let name: String
    let lat: Double
    let lon: Double
    let country: String?

    var displayName: String {
        if let country = country {
            return "\(name), \(country)"
        }
        return name
    }
}

struct GeocodingResponse: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String?

    func toCity() -> WeatherCity {
        WeatherCity(id: UUID(), name: name, lat: lat, lon: lon, country: country)
    }
}

struct FavoriteCity: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let cityName: String
    let lat: Double
    let lon: Double
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cityName = "city_name"
        case lat
        case lon
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        cityName = try container.decode(String.self, forKey: .cityName)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)

        // Handle createdAt which comes as ISO 8601 string from Supabase
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(cityName, forKey: .cityName)
        try container.encode(lat, forKey: .lat)
        try container.encode(lon, forKey: .lon)
        
        if let createdAt = createdAt {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        }
    }
}
