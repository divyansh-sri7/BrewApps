//
//  SettingsView.swift
//  GlassCast - Matches Settings.png design exactly
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(authManager: AuthenticationManager) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(authManager: authManager))
    }

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.97)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 24) {
                        unitsSection
                        notificationsSection
                        appearanceSection
                        otherSection
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UNITS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
                .padding(.leading, 20)

            VStack(spacing: 0) {
                settingsRow(icon: "thermometer", color: .red, title: "Temperature", value: viewModel.temperatureUnit.rawValue) {
                    viewModel.toggleTemperatureUnit()
                }
                Divider().padding(.leading, 60)
                settingsRow(icon: "wind", color: .red, title: "Wind Speed", value: "km/h") {}
                Divider().padding(.leading, 60)
                settingsRow(icon: "drop.fill", color: .red, title: "Precipitation", value: "mm") {}
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NOTIFICATIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
                .padding(.leading, 20)

            VStack(spacing: 0) {
                settingsRow(icon: "exclamationmark.triangle.fill", color: .red, title: "Severe Weather", subtitle: "Alerts for storms", value: "", isToggle: true) {}
                Divider().padding(.leading, 60)
                settingsRow(icon: "calendar", color: .red, title: "Daily Summary", subtitle: "Morning forecast", value: "", isToggle: false) {}
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
                .padding(.leading, 20)

            settingsRow(icon: "paintbrush.fill", color: .red, title: "Theme", value: "System Sync") {}
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)
        }
    }

    private var otherSection: some View {
        VStack(spacing: 12) {
            settingsRow(icon: "icloud.fill", color: .black, title: "Cloud Sync", value: "") {}
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)

            settingsRow(icon: "envelope.fill", color: .black, title: "Contact Support", value: "") {}
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)

            Button {
                Task { await viewModel.signOut() }
            } label: {
                HStack {
                    if viewModel.isSigningOut {
                        ProgressView()
                    } else {
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private func settingsRow(icon: String, color: Color, title: String, subtitle: String = "", value: String, isToggle: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(.black)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.black.opacity(0.5))
                    }
                }

                Spacer()

                if isToggle {
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                } else if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundStyle(.black.opacity(0.5))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.black.opacity(0.3))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.black.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
