//
//  WeatherBackground.swift
//  GlassCast
//
//  Dynamic background colors based on weather conditions
//

import SwiftUI

struct WeatherGradient {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    
    static func gradient(for condition: String) -> WeatherGradient {
        let condition = condition.lowercased()
        
        switch condition {
        case _ where condition.contains("sunny") || condition.contains("clear"):
            // Sunny - Bright blue to light yellow
            return WeatherGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.4, green: 0.7, blue: 0.95),
                    Color(red: 1.0, green: 0.85, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case _ where condition.contains("cloud"):
            // Cloudy - Gray to light blue
            return WeatherGradient(
                colors: [
                    Color(red: 0.7, green: 0.75, blue: 0.8),
                    Color(red: 0.85, green: 0.88, blue: 0.92),
                    Color(red: 0.9, green: 0.92, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case _ where condition.contains("rain") || condition.contains("drizzle"):
            // Rainy - Dark gray to slate blue
            return WeatherGradient(
                colors: [
                    Color(red: 0.3, green: 0.35, blue: 0.45),
                    Color(red: 0.5, green: 0.55, blue: 0.65),
                    Color(red: 0.65, green: 0.70, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case _ where condition.contains("thunder") || condition.contains("storm"):
            // Thunderstorm - Dark purple to dark gray
            return WeatherGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.3),
                    Color(red: 0.35, green: 0.3, blue: 0.45),
                    Color(red: 0.4, green: 0.35, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case _ where condition.contains("snow"):
            // Snow - Light blue to white
            return WeatherGradient(
                colors: [
                    Color(red: 0.8, green: 0.9, blue: 1.0),
                    Color(red: 0.9, green: 0.95, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case _ where condition.contains("mist") || condition.contains("fog") || condition.contains("haze"):
            // Fog/Mist - Grayish white
            return WeatherGradient(
                colors: [
                    Color(red: 0.75, green: 0.78, blue: 0.82),
                    Color(red: 0.85, green: 0.87, blue: 0.90),
                    Color(red: 0.92, green: 0.93, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case _ where condition.contains("wind"):
            // Windy - Blue to gray
            return WeatherGradient(
                colors: [
                    Color(red: 0.4, green: 0.6, blue: 0.85),
                    Color(red: 0.6, green: 0.75, blue: 0.90),
                    Color(red: 0.75, green: 0.80, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        default:
            // Default - Yellowish (original)
            return WeatherGradient(
                colors: [
                    Color(red: 0.95, green: 0.85, blue: 0.6),
                    Color(red: 0.98, green: 0.92, blue: 0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension View {
    func weatherBackground(_ condition: String?) -> some View {
        let gradient = WeatherGradient.gradient(for: condition ?? "clear")
        return self.background(
            LinearGradient(
                colors: gradient.colors,
                startPoint: gradient.startPoint,
                endPoint: gradient.endPoint
            )
            .ignoresSafeArea()
        )
    }
}
