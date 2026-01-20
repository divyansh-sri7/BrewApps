//
//  Constants.swift
//  GlassCast
//
//  App-wide constants
//

import Foundation

enum Constants {
    enum API {
        static let openWeatherBaseURL = "https://api.openweathermap.org/data/2.5"
        
        // MARK: - Configuration Loader
        static var openWeatherAPIKey: String {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String,
                  !key.isEmpty,
                  key != "YOUR_API_KEY_HERE" else {
                fatalError("OpenWeather API key not configured in Info.plist")
            }
            return key
        }
        
        static var supabaseURL: String {
            guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
                  !url.isEmpty,
                  url != "YOUR_SUPABASE_PROJECT_URL" else {
                fatalError("Supabase URL not configured in Info.plist")
            }
            return url
        }
        
        static var supabaseAnonKey: String {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
                  !key.isEmpty,
                  key != "YOUR_SUPABASE_ANON_KEY" else {
                fatalError("Supabase Anon Key not configured in Info.plist")
            }
            return key
        }
        
        static var supabasePublishableKey: String {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
                  !key.isEmpty else {
                return ""
            }
            return key
        }
    }

    enum UserDefaults {
        static let userKey = "glasscast_user"
        static let settingsKey = "glasscast_settings"
        static let savedCitiesKey = "glasscast_saved_cities"
    }

    enum Timeouts {
        static let standard: TimeInterval = 30
        static let upload: TimeInterval = 60
    }
}
