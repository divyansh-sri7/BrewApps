# GlassCast - AI Context File

This file provides context for AI assistants (Claude, ChatGPT, etc.) working on the GlassCast iOS weather application.

## Project Overview

**GlassCast** is a modern iOS weather application built with SwiftUI, featuring real-time weather data, city search with autocomplete, and favorites management backed by Supabase.

**Tech Stack:**
- SwiftUI (iOS 17.0+)
- Combine Framework
- Supabase (Backend as a Service)
- OpenWeatherMap API
- MVVM Architecture
- Async/Await concurrency

## Architecture Pattern: MVVM

```
View (SwiftUI) ←→ ViewModel (ObservableObject) ←→ Model/Service
```

- **Views**: SwiftUI views that observe ViewModels
- **ViewModels**: ObservableObject classes with @Published properties
- **Models**: Codable structs for data representation
- **Services**: API clients and network layer

## Critical SwiftUI Concepts

### Property Wrappers (IMPORTANT)

1. **@StateObject** - Use for creating and owning an ObservableObject
   ```swift
   @StateObject private var viewModel = CitySearchViewModel()
   ```
   - Creates the object and keeps it alive
   - Observes @Published properties
   - **Never make it optional**

2. **@ObservedObject** - Use for passing an existing ObservableObject
   ```swift
   @ObservedObject var viewModel: CitySearchViewModel
   ```
   - Doesn't own the object, just observes it
   - Observes @Published properties

3. **@State** - Use ONLY for simple value types
   ```swift
   @State private var isPresented = false
   @State private var searchText = ""
   ```
   - **NEVER use @State for ObservableObject classes**
   - Does NOT observe object property changes

4. **@Published** - Use in ObservableObject classes
   ```swift
   class ViewModel: ObservableObject {
       @Published var searchResults: [City] = []
   }
   ```
   - Notifies observers when value changes
   - Triggers SwiftUI view updates

### Common Bug: Using @State for ObservableObject

**WRONG:**
```swift
@State private var viewModel: CitySearchViewModel?
```

**CORRECT:**
```swift
@StateObject private var viewModel = CitySearchViewModel()
```

This was the root cause of the search/favorites display bug where UI wouldn't update until location button was pressed.

## Key Files and Their Responsibilities

### Core Layer

#### `/Core/Authentication/SupabaseClient.swift`
- Handles ALL Supabase REST API calls
- Methods:
  - `fetch(table:accessToken:)` - GET requests with RLS support
  - `insert(table:data:accessToken:)` - POST requests
  - `delete(table:id:accessToken:)` - DELETE requests
- Uses URLSession with async/await
- Requires access token for Row Level Security (RLS)

**Debug Logging Pattern:**
```swift
print("📡 Fetching from table: \(table)")
print("✅ Success: \(data)")
print("❌ Error: \(error)")
```

#### `/Core/Authentication/AuthManager.swift`
- Manages user authentication state
- Provides access tokens for API calls
- `@Published var currentUser: User?`
- `@Published var accessToken: String?`

#### `/Core/Config/AppConfig.swift`
- Loads environment variables
- Properties:
  - `supabaseURL: String`
  - `supabaseAnonKey: String`
  - `openWeatherAPIKey: String`
  - `supabaseConfigured: Bool`

#### `/Core/Network/WeatherService.swift`
- OpenWeatherMap API client
- Methods:
  - `searchCities(query:)` - Geocoding API
  - `getWeather(lat:lon:)` - Current weather
  - `getForecast(lat:lon:)` - 5-day forecast

### Features Layer

#### `/Features/CitySearch/ViewModels/CitySearchViewModel.swift`
**ObservableObject** managing search and favorites state.

**@Published Properties:**
- `searchText: String` - User's search input
- `searchResults: [CitySearchResult]` - API search results
- `favoriteCities: [FavoriteCity]` - User's saved favorites
- `isSearching: Bool` - Loading state for search
- `isLoadingFavorites: Bool` - Loading state for favorites

**Key Methods:**
```swift
func searchCities() async
func loadFavorites() async
func addFavorite(city: CitySearchResult) async
func removeFavorite(id: UUID) async
```

**Debouncing Pattern:**
Uses Combine's `debounce` to delay search API calls:
```swift
.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
```

#### `/Features/CitySearch/Views/CitySearchView.swift`
Alternative search view (not currently used in production).

#### `/App/MainAppView.swift`
**PRODUCTION SEARCH VIEW** - This is the active UI.

**Critical Setup:**
```swift
@StateObject private var searchViewModel: CitySearchViewModel

init(viewModel: HomeViewModel, showSearch: Binding<Bool>) {
    self.viewModel = viewModel
    self._showSearch = showSearch
    self._searchViewModel = StateObject(
        wrappedValue: CitySearchViewModel(
            accessToken: nil,
            userId: nil
        )
    )
}
```

**Display Logic Pattern:**
```swift
if !searchViewModel.searchText.isEmpty {
    // SEARCH MODE
    if searchViewModel.isSearching {
        ProgressView() // Loading
    } else if !searchViewModel.searchResults.isEmpty {
        // Show results
    } else {
        // No results found
    }
} else {
    // FAVORITES MODE
    if searchViewModel.isLoadingFavorites {
        ProgressView() // Loading
    } else if !searchViewModel.favoriteCities.isEmpty {
        // Show favorites
    } else {
        // Empty state
    }
}
```

**onAppear Pattern:**
```swift
.onAppear {
    searchViewModel.accessToken = authManager.accessToken
    searchViewModel.userId = authManager.currentUser?.id.uuidString
    Task {
        await searchViewModel.loadFavorites()
    }
}
```

### Models

#### `/Features/CitySearch/Models/CitySearchResult.swift`
```swift
struct CitySearchResult: Identifiable, Codable {
    let id = UUID()
    let name: String
    let country: String
    let state: String?
    let lat: Double
    let lon: Double
}
```

#### `/Features/CitySearch/Models/FavoriteCity.swift`
```swift
struct FavoriteCity: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let cityName: String
    let country: String?
    let latitude: Double
    let longitude: Double
    let createdAt: Date?
}
```

## Supabase Integration

### Database Schema

**Table: favorite_cities**
```sql
CREATE TABLE favorite_cities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    city_name TEXT NOT NULL,
    country TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Row Level Security (RLS)

**CRITICAL**: All queries must include user's access token.

```swift
// Get user's access token
let token = authManager.accessToken

// Pass to Supabase calls
try await supabaseClient.fetch(
    table: "favorite_cities",
    accessToken: token
)
```

**RLS Policies:**
- Users can only SELECT their own favorites (WHERE auth.uid() = user_id)
- Users can only INSERT with their own user_id
- Users can only DELETE their own favorites

### API Endpoints

**Base URL:** `https://your-project.supabase.co/rest/v1/`

**Headers Required:**
```
Content-Type: application/json
apikey: {anon_key}
Authorization: Bearer {access_token}
```

**Fetch Favorites:**
```
GET /rest/v1/favorite_cities
Authorization: Bearer {user_access_token}
```

**Add Favorite:**
```
POST /rest/v1/favorite_cities
Authorization: Bearer {user_access_token}
Body: {
    "user_id": "uuid",
    "city_name": "London",
    "country": "GB",
    "latitude": 51.5074,
    "longitude": -0.1278
}
```

**Delete Favorite:**
```
DELETE /rest/v1/favorite_cities?id=eq.{uuid}
Authorization: Bearer {user_access_token}
```

## OpenWeatherMap API

### Geocoding API (City Search)

**Endpoint:**
```
GET http://api.openweathermap.org/geo/1.0/direct
```

**Parameters:**
- `q`: City name (e.g., "London")
- `limit`: Max results (usually 5)
- `appid`: API key

**Response:**
```json
[
    {
        "name": "London",
        "country": "GB",
        "state": "England",
        "lat": 51.5074,
        "lon": -0.1278
    }
]
```

### Current Weather API

**Endpoint:**
```
GET https://api.openweathermap.org/data/2.5/weather
```

**Parameters:**
- `lat`: Latitude
- `lon`: Longitude
- `appid`: API key
- `units`: "metric" or "imperial"

## Common Issues and Solutions

### Issue: UI Not Updating When Data Changes

**Symptom:** Search results or favorites only show after pressing location button.

**Cause:** Using `@State` for ObservableObject instead of `@StateObject`.

**Solution:**
```swift
// WRONG
@State private var viewModel: CitySearchViewModel?

// CORRECT
@StateObject private var viewModel = CitySearchViewModel()
```

### Issue: Favorites Not Loading

**Checklist:**
1. Is Supabase configured? Check `AppConfig.supabaseConfigured`
2. Is user authenticated? Check `authManager.accessToken != nil`
3. Are RLS policies correct? Verify in Supabase dashboard
4. Is access token being passed? Check `loadFavorites()` implementation

**Debug:**
```swift
print("Access token: \(accessToken ?? "nil")")
print("User ID: \(userId ?? "nil")")
```

### Issue: Search Results Empty

**Checklist:**
1. Is OpenWeatherMap API key valid?
2. Is network reachable?
3. Is search query valid? (at least 3 characters recommended)
4. Check API response in debug logs

**Debug:**
```swift
print("Search query: \(query)")
print("API response: \(responseData)")
```

### Issue: "Invalid Response" from Supabase

**Common Causes:**
1. Missing or invalid access token
2. RLS policy blocking the request
3. Invalid table name
4. Missing required fields in POST body

**Fix:**
- Check HTTP status code in logs
- Verify access token is not nil
- Test query in Supabase SQL editor
- Check response body for error details

## Best Practices for AI Assistants

### 1. Always Read Files Before Editing
```swift
// WRONG: Making changes without reading
// Edit file based on assumptions

// CORRECT:
// Use Read tool first to see actual code
// Then use Edit tool with exact strings
```

### 2. Understand SwiftUI Property Wrappers
- **@StateObject** owns and observes
- **@ObservedObject** observes only
- **@State** for simple values only
- Never mix up these patterns

### 3. Check Actual UI File
- MainAppView.swift is the production UI
- CitySearchView.swift is an alternative (not used)
- Always verify which file user is referring to

### 4. Async/Await Patterns
```swift
// Correct pattern
Task {
    await viewModel.loadFavorites()
}

// In ViewModel
func loadFavorites() async {
    do {
        let data = try await supabaseClient.fetch(...)
    } catch {
        print("Error: \(error)")
    }
}
```

### 5. Debug Logging
Add comprehensive logging:
- 📡 Network requests
- 🔄 Loading states
- ✅ Success messages
- ❌ Errors with details

### 6. Testing Checklist
When making changes:
- [ ] Does it compile?
- [ ] Are all property wrappers correct?
- [ ] Is async/await used properly?
- [ ] Are access tokens being passed?
- [ ] Is error handling present?
- [ ] Are debug logs added?

## Environment Variables

**Required:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous/public key
- `OPENWEATHER_API_KEY` - OpenWeatherMap API key

**Access in Code:**
```swift
let config = AppConfig.shared
print(config.supabaseURL)
print(config.supabaseAnonKey)
print(config.openWeatherAPIKey)
```

## Build Commands

```bash
# Navigate to project
cd /Users/divyansh/Desktop/IOS/BrewApps/GlassCast

# Build for simulator
xcodebuild -scheme GlassCast -sdk iphonesimulator build

# Clean build
xcodebuild clean -scheme GlassCast
```

## Key Takeaways for AI Assistants

1. **MainAppView.swift is the production UI** - not CitySearchView.swift
2. **Always use @StateObject for ViewModels** - never @State
3. **RLS requires access tokens** - always pass them to Supabase calls
4. **Read files before editing** - don't assume code structure
5. **Add debug logging** - helps diagnose issues quickly
6. **Test the actual flow** - search typing → results display → favorites loading

## Common User Requests

- "Fix search not showing results" → Check @StateObject usage
- "Favorites not loading" → Check access token and RLS
- "UI not updating" → Check property wrapper types
- "Add new feature" → Follow MVVM pattern, add to appropriate layer

## File Reading Priority

When debugging issues:
1. Read MainAppView.swift (actual UI)
2. Read CitySearchViewModel.swift (state management)
3. Read SupabaseClient.swift (API calls)
4. Read AppConfig.swift (configuration)

## Version Info

- **iOS Target:** 17.0+
- **Xcode:** 15.0+
- **Swift:** 5.9+
- **SwiftUI:** Latest

---

**Last Updated:** January 2026

This context file should be kept up to date as the project evolves. When making significant architectural changes, update this file accordingly.
