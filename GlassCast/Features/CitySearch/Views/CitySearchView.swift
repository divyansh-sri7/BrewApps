//
//  CitySearchView.swift
//  GlassCast - With live search and favorites
//

import SwiftUI

struct CitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var viewModel: CitySearchViewModel
    @Binding var selectedCity: String?

    init(selectedCity: Binding<String?> = .constant(nil), accessToken: String? = nil, userId: String? = nil) {
        _selectedCity = selectedCity
        _viewModel = StateObject(wrappedValue: CitySearchViewModel(accessToken: accessToken, userId: userId))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.85, blue: 0.9), Color(red: 0.88, green: 0.9, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchBar

                ScrollView {
                    VStack(spacing: 16) {
                        if !viewModel.searchText.isEmpty {
                            // Show search results when user is typing
                            if viewModel.isSearching {
                                ProgressView()
                                    .padding(.top, 100)
                            } else if !viewModel.searchResults.isEmpty {
                                searchResultsSection
                            } else {
                                noResultsView
                            }
                        } else {
                            // Show favorites when not searching
                            if viewModel.isLoadingFavorites {
                                ProgressView()
                                    .padding(.top, 100)
                            } else if !viewModel.favoriteCities.isEmpty {
                                favoritesSection
                            } else {
                                emptyState
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .toast(message: $viewModel.errorMessage)
        .onAppear {
            print("🔵 CitySearchView appeared")
            print("🔵 Auth token from manager: \(authManager.accessToken != nil ? "available" : "nil")")
            print("🔵 User ID from manager: \(authManager.currentUser?.id.uuidString ?? "nil")")

            viewModel.accessToken = authManager.accessToken
            viewModel.userId = authManager.currentUser?.id.uuidString
            Task {
                await viewModel.loadFavorites()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Weather")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.black.opacity(0.4))
            TextField("Search city..", text: $viewModel.searchText)
                .foregroundStyle(.black)

            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEARCH RESULTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
                .padding(.leading, 20)

            ForEach(viewModel.searchResults) { city in
                citySearchCard(city: city)
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MY FAVORITES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
                .padding(.leading, 20)

            ForEach(viewModel.favoriteCities) { favorite in
                favoriteCard(favorite: favorite)
            }
        }
    }

    private var emptyState: some View {
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

    private var noResultsView: some View {
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

    private func citySearchCard(city: WeatherCity) -> some View {
        Button {
            Task {
                await viewModel.addToFavorites(city: city)
                selectedCity = city.name
                dismiss()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black)

                    if let country = city.country {
                        Text(country)
                            .font(.system(size: 14))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: viewModel.isFavorite(city: city) ? "star.fill" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(viewModel.isFavorite(city: city) ? .yellow : .black.opacity(0.4))
            }
            .padding(20)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    private func favoriteCard(favorite: FavoriteCity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.cityName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.black)

                Text("Favorite")
                    .font(.system(size: 14))
                    .foregroundStyle(.black.opacity(0.6))
            }

            Spacer()

            Button {
                Task {
                    selectedCity = favorite.cityName
                    dismiss()
                }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
            }

            Button {
                Task {
                    await viewModel.removeFromFavorites(id: favorite.id)
                }
            } label: {
                Image(systemName: "star.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
