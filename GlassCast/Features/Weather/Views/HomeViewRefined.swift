//
//  HomeView.swift
//  GlassCast - Matches Home.png design exactly
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showSettings = false
    @State private var showCitySearch = false

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    var body: some View {
        ZStack {
            // Dynamic background based on weather condition
            if let weather = viewModel.currentWeather {
                LinearGradient(
                    colors: WeatherGradient.gradient(for: weather.condition).colors,
                    startPoint: WeatherGradient.gradient(for: weather.condition).startPoint,
                    endPoint: WeatherGradient.gradient(for: weather.condition).endPoint
                )
                .ignoresSafeArea()
            } else {
                // Default background while loading
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.85, blue: 0.6), Color(red: 0.98, green: 0.92, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header

                    if viewModel.isLoading && viewModel.currentWeather == nil {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(1.2)
                            .padding(.top, 100)
                    } else if let weather = viewModel.currentWeather {
                        VStack(spacing: 8) {
                            Text("\(Int(weather.temperature.rounded()))°")
                                .font(.system(size: 80, weight: .thin))
                                .foregroundStyle(.black)

                            Text(weather.conditionDescription.uppercased())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.black.opacity(0.7))

                            HStack(spacing: 12) {
                                Text("H:\(Int(weather.highTemp.rounded()))°")
                                Text("L:\(Int(weather.lowTemp.rounded()))°")
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(.black.opacity(0.6))
                            .padding(.top, 4)
                        }
                        .padding(.top, 40)

                        forecastSection
                    } else if !viewModel.isLoading {
                        emptyState
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 120)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(authManager: authManager)
        }
        .sheet(isPresented: $showCitySearch) {
            CitySearchView(
                selectedCity: $viewModel.selectedCity,
                accessToken: authManager.accessToken,
                userId: authManager.currentUser?.id.uuidString
            )
                .environmentObject(authManager)
        }
        .onChange(of: viewModel.selectedCity) { _, newCity in
            if let city = newCity {
                Task { await viewModel.loadWeatherForCity(city) }
            }
        }
        .task {
            if viewModel.currentWeather == nil {
                await viewModel.loadWeather()
            }
        }
    }

    private var header: some View {
        HStack {
            if let city = viewModel.selectedCity {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                    Text(city.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.black)
            } else {
                Text("Weather")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
            }

            Spacer()

            Button {
                showCitySearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(18)
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundStyle(.black.opacity(0.3))
                .padding(.top, 80)

            Text("No Location Set")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.black)

            Text("Search for a city to view weather")
                .font(.system(size: 16))
                .foregroundStyle(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showCitySearch = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search Cities")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.7))
                .cornerRadius(25)
            }
            .padding(.top, 8)
        }
    }

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                Text("5-DAY FORECAST")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.black.opacity(0.6))
            .padding(.leading, 20)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.forecast.prefix(5).enumerated()), id: \.element.id) { index, day in
                    HStack {
                        Text(day.dayName)
                            .font(.system(size: 15))
                            .frame(width: 60, alignment: .leading)

                        Image(systemName: weatherIcon(for: day.icon))
                            .font(.system(size: 20))
                            .frame(width: 40)

                        Spacer()

                        Text("\(Int(day.highTemp.rounded()))°")
                            .font(.system(size: 15, weight: .medium))
                        Text("\(Int(day.lowTemp.rounded()))°")
                            .font(.system(size: 15))
                            .foregroundStyle(.black.opacity(0.5))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    if index < 4 {
                        Divider().padding(.horizontal, 20)
                    }
                }
            }
            .background(Color.white.opacity(0.3))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
    }

    private func weatherIcon(for code: String) -> String {
        switch code {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.rain.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "sun.max.fill"
        }
    }
}
