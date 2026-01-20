//
//  HomeViewModel.swift
//  GlassCast
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var currentWeather: CurrentWeather?
    @Published var forecast: [DailyForecast] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var selectedCity: String? = nil

    private let weatherService: WeatherService
    private let locationService: LocationService = LocationService()

    init(weatherService: WeatherService = WeatherService()) {
        self.weatherService = weatherService
        // Load weather for first city or wait for user action
        Task {
            await loadWeatherForCurrentLocation()
        }
    }

    // MARK: - Public Methods

    func loadWeather() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        await fetchWeatherData()

        isLoading = false
    }

    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        errorMessage = nil

        await fetchWeatherData()

        isRefreshing = false
    }

    func loadWeatherForCity(_ city: String) async {
        selectedCity = city
        await loadWeather()
    }

    func loadWeatherForCurrentLocation() async {
        isLoading = true
        errorMessage = nil

        if let city = await locationService.getCurrentLocationCity() {
            selectedCity = city
            await fetchWeatherData()
        } else {
            // No fallback - let user search for a city
            selectedCity = nil
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func fetchWeatherData() async {
        guard let city = selectedCity else { return }

        do {
            async let weather = weatherService.fetchCurrentWeather(city: city)
            async let forecastData = weatherService.fetchForecast(city: city)

            let (weatherResult, forecastResult) = try await (weather, forecastData)

            currentWeather = weatherResult
            forecast = forecastResult
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        if let weatherError = error as? WeatherError {
            errorMessage = weatherError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }

        currentWeather = nil
        forecast = []
    }
}
