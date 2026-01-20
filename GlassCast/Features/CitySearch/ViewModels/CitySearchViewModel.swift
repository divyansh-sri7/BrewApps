//
//  CitySearchViewModel.swift
//  GlassCast
//

import Foundation
import Combine

@MainActor
final class CitySearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [WeatherCity] = []
    @Published var favoriteCities: [FavoriteCity] = []
    @Published var isSearching = false
    @Published var isLoadingFavorites = false
    @Published var errorMessage: String?

    private let weatherService = WeatherService()
    private let supabaseClient = SupabaseClient.shared
    private let config = ConfigurationManager.shared
    private var searchTask: Task<Void, Never>?
    var accessToken: String?
    var userId: String?

    init(accessToken: String? = nil, userId: String? = nil) {
        self.accessToken = accessToken
        self.userId = userId
        setupSearchDebouncing()
    }

    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                Task { await self?.searchCities(query: text) }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func searchCities(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask?.cancel()
        isSearching = true

        searchTask = Task {
            do {
                let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String ?? ""
                let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(query)&limit=5&appid=\(apiKey)"

                guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
                    print("Invalid URL for query: \(query)")
                    isSearching = false
                    return
                }

                print("Searching cities with URL: \(url.absoluteString)")

                let (data, _) = try await URLSession.shared.data(from: url)
                let results = try JSONDecoder().decode([GeocodingResponse].self, from: data)

                print("Search results count: \(results.count)")

                if !Task.isCancelled {
                    searchResults = results.map { $0.toCity() }
                    print("Updated searchResults to \(searchResults.count) cities")
                }
            } catch {
                print("Search error: \(error)")
                if !Task.isCancelled {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }

            isSearching = false
        }
    }

    func addToFavorites(city: WeatherCity) async {
        guard config.supabaseConfigured else {
            errorMessage = "Supabase not configured"
            return
        }

        do {
            var favoriteCity = [
                "city_name": city.name,
                "lat": city.lat,
                "lon": city.lon
            ] as [String: Any]
            
            // Include user_id from authenticated user
            if let userId = userId {
                favoriteCity["user_id"] = userId
            }

            try await supabaseClient.insert(table: "favorite_cities", values: favoriteCity, accessToken: accessToken)
            await loadFavorites()
        } catch {
            print("Error adding favorite: \(error)")
            errorMessage = "Failed to add favorite"
        }
    }

    func removeFromFavorites(id: UUID) async {
        guard config.supabaseConfigured else { return }

        do {
            try await supabaseClient.delete(table: "favorite_cities", id: id.uuidString, accessToken: accessToken)
            await loadFavorites()
        } catch {
            errorMessage = "Failed to remove favorite"
        }
    }

    func loadFavorites() async {
        guard config.supabaseConfigured else {
            print("⚠️ Supabase not configured")
            return
        }

        print("🔄 Starting to load favorites...")
        print("🔄 Access token available: \(accessToken != nil)")
        print("🔄 User ID: \(userId ?? "nil")")

        isLoadingFavorites = true

        do {
            let data = try await supabaseClient.fetch(table: "favorite_cities", accessToken: accessToken)
            print("✅ Received data from Supabase, size: \(data.count) bytes")

            favoriteCities = try JSONDecoder().decode([FavoriteCity].self, from: data)
            print("✅ Decoded \(favoriteCities.count) favorite cities")
        } catch {
            print("❌ Failed to load favorites: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error: \(decodingError)")
            }
        }

        isLoadingFavorites = false
        print("🔄 Finished loading favorites")
    }

    func isFavorite(city: WeatherCity) -> Bool {
        favoriteCities.contains { $0.cityName == city.name }
    }
}
