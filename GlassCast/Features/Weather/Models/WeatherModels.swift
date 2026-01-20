//
//  WeatherModels.swift
//  GlassCast
//

import Foundation

// MARK: - API Response Models

struct CurrentWeatherResponse: Decodable {
    let coord: Coordinates
    let weather: [WeatherCondition]
    let main: MainWeather
    let wind: Wind
    let dt: Int
    let name: String
    let sys: System
}

struct ForecastResponse: Decodable {
    let list: [ForecastItem]
    let city: City
}

struct ForecastItem: Decodable {
    let dt: Int
    let main: MainWeather
    let weather: [WeatherCondition]
    let wind: Wind
    let pop: Double
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, wind, pop
        case dtTxt = "dt_txt"
    }
}

struct Coordinates: Decodable {
    let lon: Double
    let lat: Double
}

struct WeatherCondition: Decodable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Decodable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure, humidity
    }
}

struct Wind: Decodable {
    let speed: Double
    let deg: Int
}

struct System: Decodable {
    let country: String
    let sunrise: Int
    let sunset: Int
}

struct City: Decodable {
    let name: String
    let country: String
}

// MARK: - App Domain Models

struct CurrentWeather: Identifiable {
    let id = UUID()
    let cityName: String
    let country: String
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let conditionDescription: String
    let icon: String
    let highTemp: Double
    let lowTemp: Double
    let humidity: Int
    let windSpeed: Double
    let timestamp: Date

    init(from response: CurrentWeatherResponse) {
        self.cityName = response.name
        self.country = response.sys.country
        self.temperature = response.main.temp
        self.feelsLike = response.main.feelsLike
        self.condition = response.weather.first?.main ?? ""
        self.conditionDescription = response.weather.first?.description ?? ""
        self.icon = response.weather.first?.icon ?? ""
        self.highTemp = response.main.tempMax
        self.lowTemp = response.main.tempMin
        self.humidity = response.main.humidity
        self.windSpeed = response.wind.speed
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(response.dt))
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let icon: String
    let highTemp: Double
    let lowTemp: Double
    let condition: String
}
