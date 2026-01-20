//
//  AppCoordinator.swift
//  GlassCast
//
//  Main app coordinator based on authentication state
//

import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        ZStack {
            switch authManager.authState {
            case .loading:
                LoadingView()

            case .authenticated:
                MainAppView()
                    .environmentObject(authManager)

            case .unauthenticated:
                AuthenticationFlow()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.authState)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.authPrimaryGradient, .authSecondaryGradient],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "cloud.rain.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)

                Text("GlassCast")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Authentication Flow

struct AuthenticationFlow: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        AuthView(authManager: authManager)
    }
}

// MainTabView is now in separate file
