//
//  GlassCastApp.swift
//  GlassCast
//
//  Created by Divyansh Srivastava on 20/01/26.
//

import SwiftUI

@main
struct GlassCastApp: App {
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(authManager)
        }
    }
}
