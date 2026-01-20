//
//  SettingsViewModel.swift
//  GlassCast
//

import Foundation
import Combine

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"

    var apiUnit: String {
        switch self {
        case .celsius: return "metric"
        case .fahrenheit: return "imperial"
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var temperatureUnit: TemperatureUnit = .celsius
    @Published var isSigningOut = false
    @Published var errorMessage: String?

    private let authManager: AuthenticationManager
    private let settingsKey = "glasscast_temperature_unit"

    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        loadSettings()
    }

    // MARK: - Public Methods

    func toggleTemperatureUnit() {
        temperatureUnit = temperatureUnit == .celsius ? .fahrenheit : .celsius
        saveSettings()
    }

    func signOut() async {
        isSigningOut = true
        await authManager.signOut()
        isSigningOut = false
    }

    // MARK: - Private Methods

    private func saveSettings() {
        UserDefaults.standard.set(temperatureUnit.rawValue, forKey: settingsKey)
    }

    private func loadSettings() {
        if let saved = UserDefaults.standard.string(forKey: settingsKey),
           let unit = TemperatureUnit(rawValue: saved) {
            temperatureUnit = unit
        }
    }
}
