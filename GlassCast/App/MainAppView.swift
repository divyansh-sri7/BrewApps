//
//  MainAppView.swift
//  GlassCast
//
//  Main app screen with full-page navigation and bottom control bar
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var viewModel: HomeViewModel = HomeViewModel()
    @State private var showSearch = false
    @State private var showSettings = false
    @State private var selectedCity: String?
    
    var body: some View {
        ZStack {
            // Dynamic background based on weather
            if let weather = viewModel.currentWeather {
                LinearGradient(
                    colors: WeatherGradient.gradient(for: weather.condition).colors,
                    startPoint: WeatherGradient.gradient(for: weather.condition).startPoint,
                    endPoint: WeatherGradient.gradient(for: weather.condition).endPoint
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.85, blue: 0.6), Color(red: 0.98, green: 0.92, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    if showSearch {
                        CitySearchFullPage(
                            viewModel: viewModel,
                            showSearch: $showSearch
                        )
                        .environmentObject(authManager)
                    } else if showSettings {
                        SettingsView(authManager: authManager)
                            .environmentObject(authManager)
                    } else {
                        HomeViewNew(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom control bar
                bottomControlBar
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
            }
        }
        .task {
            if viewModel.currentWeather == nil {
                await viewModel.loadWeather()
            }
        }
    }

    private var bottomControlBar: some View {
        HStack(spacing: 12) {
            // Location button
            Button {
                Task {
                    await viewModel.loadWeatherForCurrentLocation()
                }
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .blur(radius: 10)
                    }
            }

            // Search button (pill shape)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSearch = true
                    showSettings = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                    Text("Search City")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .blur(radius: 10)
                }
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
            }

            // Settings or Home button (toggles based on current view)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if showSettings {
                        // If in settings, go back to home
                        showSettings = false
                        showSearch = false
                    } else {
                        // If in home, go to settings
                        showSettings = true
                        showSearch = false
                    }
                }
            } label: {
                Image(systemName: showSettings ? "house.fill" : "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .blur(radius: 10)
                    }
            }
        }
    }
}

// MARK: - Home View (New Full Page Version)

struct HomeViewNew: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Location header
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text((viewModel.selectedCity ?? "Current Location").uppercased())
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                }
                .padding(.top, 40)

                // Weather display
                if viewModel.isLoading && viewModel.currentWeather == nil {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.black)
                        .padding(.top, 100)
                } else if let weather = viewModel.currentWeather {
                    VStack(spacing: 16) {
                        // Temperature
                        VStack(spacing: 4) {
                            Text("\(Int(weather.temperature.rounded()))°")
                                .font(.system(size: 100, weight: .thin))
                                .foregroundStyle(.black)

                            Text(weather.conditionDescription.uppercased())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.black.opacity(0.7))
                        }

                        // High/Low
                        HStack(spacing: 12) {
                            Text("H:\(Int(weather.highTemp.rounded()))°")
                            Text("L:\(Int(weather.lowTemp.rounded()))°")
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(.black.opacity(0.6))

                        // Details grid
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                DetailCard(
                                    icon: "humidity.fill",
                                    title: "Humidity",
                                    value: "\(weather.humidity)%"
                                )

                                DetailCard(
                                    icon: "wind",
                                    title: "Wind",
                                    value: "\(String(format: "%.1f", weather.windSpeed)) m/s"
                                )
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.vertical, 40)

                    // Forecast section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("5-DAY FORECAST")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.6))
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.forecast) { day in
                                    ForecastCard(forecast: day)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Detail Card

struct DetailCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.black.opacity(0.7))

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.black.opacity(0.6))

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.15))
                .blur(radius: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Forecast Card

struct ForecastCard: View {
    let forecast: DailyForecast

    var body: some View {
        VStack(spacing: 12) {
            Text(forecast.dayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.black)

            Image(systemName: getWeatherIcon(forecast.icon))
                .font(.system(size: 24))
                .foregroundStyle(.black)

            VStack(spacing: 4) {
                Text("\(Int(forecast.highTemp.rounded()))°")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)

                Text("\(Int(forecast.lowTemp.rounded()))°")
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(0.6))
            }
        }
        .frame(maxWidth: 80)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
                .blur(radius: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }

    private func getWeatherIcon(_ icon: String) -> String {
        switch icon {
        case "01d", "01n": return "sun.max.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.rain.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - Full Page Search

struct CitySearchFullPage: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Binding var showSearch: Bool
    @StateObject private var searchViewModel: CitySearchViewModel

    init(viewModel: HomeViewModel, showSearch: Binding<Bool>) {
        self.viewModel = viewModel
        self._showSearch = showSearch
        self._searchViewModel = StateObject(wrappedValue: CitySearchViewModel(accessToken: nil, userId: nil))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Search Cities")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black)
                    Spacer()
                    Button {
                        showSearch = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(20)

                // Search bar
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.black.opacity(0.4))
                        TextField("Search city..", text: $searchViewModel.searchText)
                            .foregroundStyle(.black)
                            .tint(.black)

                        if searchViewModel.isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // Results
                    ScrollView {
                        VStack(spacing: 12) {
                            if !searchViewModel.searchText.isEmpty {
                                // Show search results when user is typing
                                if searchViewModel.isSearching {
                                    ProgressView()
                                        .padding(.top, 100)
                                } else if !searchViewModel.searchResults.isEmpty {
                                    Text("SEARCH RESULTS")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.black.opacity(0.5))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)

                                    ForEach(searchViewModel.searchResults) { city in
                                        citySearchResultRow(city: city, searchViewModel: searchViewModel)
                                    }
                                } else {
                                    // No results found
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.magnifyingglass")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.black.opacity(0.3))
                                            .padding(.top, 60)

                                        Text("No cities found")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.black.opacity(0.6))

                                        Text("Try a different search")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.black.opacity(0.5))
                                    }
                                }
                            } else {
                                // Show favorites when not searching
                                if searchViewModel.isLoadingFavorites {
                                    ProgressView()
                                        .padding(.top, 100)
                                } else if !searchViewModel.favoriteCities.isEmpty {
                                    Text("MY FAVORITES")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.black.opacity(0.5))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)

                                    ForEach(searchViewModel.favoriteCities) { favorite in
                                        favoriteCityRow(favorite: favorite, searchViewModel: searchViewModel)
                                    }
                                } else {
                                    // Empty state
                                    VStack(spacing: 16) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.black.opacity(0.3))
                                            .padding(.top, 60)

                                        Text("Search for cities")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.black.opacity(0.6))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            // Update auth credentials and load favorites when view appears
            searchViewModel.accessToken = authManager.accessToken
            searchViewModel.userId = authManager.currentUser?.id.uuidString
            Task {
                await searchViewModel.loadFavorites()
            }
        }
    }

    private func citySearchResultRow(city: WeatherCity, searchViewModel: CitySearchViewModel) -> some View {
        Button {
            Task {
                await searchViewModel.addToFavorites(city: city)
                viewModel.selectedCity = city.name
                await viewModel.loadWeatherForCity(city.name)
                showSearch = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)

                    if let country = city.country {
                        Text(country)
                            .font(.system(size: 14))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: searchViewModel.isFavorite(city: city) ? "star.fill" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(searchViewModel.isFavorite(city: city) ? .yellow : .black.opacity(0.4))
            }
            .padding(16)
            .background(.white.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }

    private func favoriteCityRow(favorite: FavoriteCity, searchViewModel: CitySearchViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.cityName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                Text("Favorite")
                    .font(.system(size: 14))
                    .foregroundStyle(.black.opacity(0.6))
            }

            Spacer()

            Button {
                viewModel.selectedCity = favorite.cityName
                Task {
                    await viewModel.loadWeatherForCity(favorite.cityName)
                }
                showSearch = false
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
            }

            Button {
                Task {
                    await searchViewModel.removeFromFavorites(id: favorite.id)
                }
            } label: {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(16)
        .background(.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

#Preview {
    MainAppView()
        .environmentObject(AuthenticationManager())
}
