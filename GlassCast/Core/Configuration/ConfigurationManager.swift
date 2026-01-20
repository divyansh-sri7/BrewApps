//
//  ConfigurationManager.swift
//  GlassCast
//
//  Centralized configuration manager for API credentials and settings
//

import Foundation

@MainActor
final class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private init() {}
    
    // MARK: - Weather Configuration
    
    var weatherAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_API_KEY_HERE" else {
            return ""
        }
        return key
    }
    
    var weatherAPIConfigured: Bool {
        !weatherAPIKey.isEmpty
    }
    
    // MARK: - Supabase Configuration
    
    var supabaseURL: URL? {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty,
              urlString != "YOUR_SUPABASE_PROJECT_URL" else {
            return nil
        }
        return URL(string: urlString)
    }
    
    var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_SUPABASE_ANON_KEY" else {
            return ""
        }
        return key
    }
    
    var supabasePublishableKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
              !key.isEmpty else {
            return ""
        }
        return key
    }
    
    var supabaseConfigured: Bool {
        supabaseURL != nil && !supabaseAnonKey.isEmpty
    }
    
    // MARK: - Configuration Status
    
    func printConfigurationStatus() {
        print("=== GlassCast Configuration Status ===")
        print("Weather API Configured: \(weatherAPIConfigured)")
        print("Supabase Configured: \(supabaseConfigured)")
        if let supabaseURL = supabaseURL {
            print("Supabase URL: \(supabaseURL.absoluteString)")
        }
        print("=====================================")
    }
}
