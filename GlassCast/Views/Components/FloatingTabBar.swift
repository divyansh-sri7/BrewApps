//
//  FloatingTabBar.swift
//  GlassCast
//

import SwiftUI

enum Tab {
    case home
    case search
    case settings
}

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 50) {
            TabButton(icon: "house.fill", isSelected: selectedTab == .home) {
                selectedTab = .home
            }

            TabButton(icon: "magnifyingglass", isSelected: selectedTab == .search) {
                selectedTab = .search
            }

            TabButton(icon: "gearshape.fill", isSelected: selectedTab == .settings) {
                selectedTab = .settings
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 5)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(isSelected ? .black : .black.opacity(0.4))
                .frame(width: 44, height: 44)
        }
    }
}
