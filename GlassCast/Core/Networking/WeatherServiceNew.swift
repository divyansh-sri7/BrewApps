//
//  WeatherService.swift
//  GlassCast
//

import Foundation

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingAPIKey
    case networkError(Error)
    case decodingError
    case cityNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .missingAPIKey:
            return "Weather API key not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to process weather data"
        case .cityNotFound:
            return "City not found"
        }
    }
}

final class WeatherService {
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let apiKey: String
    private let config = ConfigurationManager.shared

    init() {
        self.apiKey = config.weatherAPIKey
    }

    // MARK: - Public Methods

    func fetchCurrentWeather(city: String, units: String = "metric") async throws -> CurrentWeather {
        guard !apiKey.isEmpty else {
            throw WeatherError.missingAPIKey
        }

        let urlString = "\(baseURL)/weather?q=\(city)&appid=\(apiKey)&units=\(units)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw WeatherError.cityNotFound
            }
            throw WeatherError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(CurrentWeatherResponse.self, from: data)
            return CurrentWeather(from: weatherResponse)
        } catch {
            throw WeatherError.decodingError
        }
    }

    func fetchForecast(city: String, units: String = "metric") async throws -> [DailyForecast] {
        guard !apiKey.isEmpty else {
            throw WeatherError.missingAPIKey
        }

        let urlString = "\(baseURL)/forecast?q=\(city)&appid=\(apiKey)&units=\(units)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
            return processForecastData(forecastResponse.list)
        } catch {
            throw WeatherError.decodingError
        }
    }

    // MARK: - Private Methods

    private func processForecastData(_ items: [ForecastItem]) -> [DailyForecast] {
        let calendar = Calendar.current
        var dailyData: [Date: (high: Double, low: Double, icon: String, condition: String)] = [:]

        for item in items {
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let startOfDay = calendar.startOfDay(for: date)

            if let existing = dailyData[startOfDay] {
                dailyData[startOfDay] = (
                    high: max(existing.high, item.main.tempMax),
                    low: min(existing.low, item.main.tempMin),
                    icon: existing.icon,
                    condition: existing.condition
                )
            } else {
                dailyData[startOfDay] = (
                    high: item.main.tempMax,
                    low: item.main.tempMin,
                    icon: item.weather.first?.icon ?? "",
                    condition: item.weather.first?.main ?? ""
                )
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"

        return dailyData.keys.sorted().prefix(5).map { date in
            let data = dailyData[date]!
            let dayName: String

            if calendar.isDateInToday(date) {
                dayName = "Today"
            } else if calendar.isDateInTomorrow(date) {
                dayName = "Tomorrow"
            } else {
                dayName = dateFormatter.string(from: date)
            }

            return DailyForecast(
                date: date,
                dayName: dayName,
                icon: data.icon,
                highTemp: data.high,
                lowTemp: data.low,
                condition: data.condition
            )
        }
    }
}
