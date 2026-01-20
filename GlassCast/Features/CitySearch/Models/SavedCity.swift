//
//  SavedCity.swift
//  GlassCast
//
//  Created by Claude on 20/01/26.
//

import Foundation

struct SavedCity: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let isCurrentLocation: Bool

    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, isCurrentLocation: Bool = false) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isCurrentLocation = isCurrentLocation
    }

    static func == (lhs: SavedCity, rhs: SavedCity) -> Bool {
        lhs.id == rhs.id
    }
}
