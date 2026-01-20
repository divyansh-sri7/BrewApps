//
//  User.swift
//  GlassCast
//
//  Created by Claude on 20/01/26.
//

import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let createdAt: Date

    init(id: UUID = UUID(), email: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}
