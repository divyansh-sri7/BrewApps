//
//  MainTabView.swift
//  GlassCast
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .search:
                    CitySearchView(
                        selectedCity: .constant(nil),
                        accessToken: authManager.accessToken,
                        userId: authManager.currentUser?.id.uuidString
                    )
                    .environmentObject(authManager)
                case .settings:
                    SettingsView(authManager: authManager)
                }
            }
            .transition(.opacity)

            // Floating tab bar
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}
