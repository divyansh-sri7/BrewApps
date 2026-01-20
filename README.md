# GlassCast

A modern iOS weather application built with SwiftUI, featuring real-time weather data, city search, and favorites management.

## Features

- Real-time weather data from OpenWeatherMap API
- City search with autocomplete
- Favorite cities management with Supabase backend
- User authentication with Supabase
- Location-based weather
- Clean, modern UI with glass morphism design
- 5-day weather forecast
- Temperature and unit preferences

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Supabase account
- OpenWeatherMap API account

## Architecture

### MVVM Pattern
```
GlassCast/
├── App/                                    # Application entry point
│   ├── GlassCastApp.swift                 # Main app struct
│   └── MainAppView.swift                   # Main navigation view
│
├── Core/                                   # Core infrastructure
│   ├── Authentication/
│   │   ├── AuthManager.swift              # Authentication state management
│   │   └── SupabaseClient.swift           # Supabase REST API client
│   ├── Configuration/
│   │   └── AppConfig.swift                # Environment variables & config
│   ├── Extensions/                        # Swift extensions
│   ├── Models/                            # Shared models
│   ├── Networking/
│   │   └── WeatherService.swift           # OpenWeatherMap API service
│   └── Utilities/                         # Utility classes
│
├── Features/                               # Feature modules (MVVM)
│   ├── Authentication/
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   └── Views/
│   │       ├── SignInView.swift
│   │       └── SignUpView.swift
│   ├── CitySearch/
│   │   ├── Models/
│   │   │   ├── CitySearchResult.swift
│   │   │   └── FavoriteCity.swift
│   │   ├── ViewModels/
│   │   │   └── CitySearchViewModel.swift
│   │   └── Views/
│   │       └── CitySearchView.swift
│   ├── Settings/
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   └── Views/
│   │       └── SettingsView.swift
│   └── Weather/
│       ├── Models/
│       │   └── WeatherData.swift
│       ├── ViewModels/
│       │   └── HomeViewModel.swift
│       └── Views/
│           └── HomeView.swift
│
├── Views/                                  # Legacy/shared views
│   ├── Auth/
│   ├── CitySearch/
│   ├── Components/                        # Reusable UI components
│   ├── Home/
│   └── Settings/
│
├── ViewModels/                             # Legacy ViewModels (being migrated)
├── Models/                                 # Legacy Models (being migrated)
├── Services/                               # Legacy Services (being migrated)
├── Extensions/                             # Global extensions
├── Utils/                                  # Utility functions
│
└── Resources/
    ├── Assets.xcassets                    # Images, colors, icons
    └── Fonts/                             # Custom fonts
```

## Setup Instructions

### 1. Clone or Open the Project

```bash
cd /Users/divyansh/Desktop/IOS/BrewApps/GlassCast
open GlassCast.xcodeproj
```

### 2. Configure Supabase

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Go to Project Settings > API
4. Copy your:
   - Project URL (e.g., `https://xxxxx.supabase.co`)
   - anon/public key

#### Set Up Database Schema

Run this SQL in your Supabase SQL Editor:

```sql
-- Create favorite_cities table
CREATE TABLE public.favorite_cities (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    city_name TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT now(),
    CONSTRAINT favorite_cities_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Enable Row Level Security
ALTER TABLE public.favorite_cities ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own cities
CREATE POLICY "Users can read their own cities"
    ON public.favorite_cities
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Policy: Users can add their own cities
CREATE POLICY "Users can add their own cities"
    ON public.favorite_cities
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own cities
CREATE POLICY "Users can delete their own cities"
    ON public.favorite_cities
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
```

#### Configure Environment Variables in Xcode

**Option 1: Using Build Settings (Recommended)**

1. Open `GlassCast.xcodeproj` in Xcode
2. Select the GlassCast project in the navigator
3. Select the GlassCast target
4. Go to "Build Settings" tab
5. Search for "User-Defined"
6. Click the "+" button to add new settings:
   - `SUPABASE_URL` = `https://your-project.supabase.co`
   - `SUPABASE_ANON_KEY` = `your-anon-key-here`
   - `OPENWEATHER_API_KEY` = `your-api-key-here`

**Option 2: Using Info.plist**

Add these keys to your `Info.plist`:

```xml
<key>SupabaseURL</key>
<string>https://your-project.supabase.co</string>
<key>SupabaseAnonKey</key>
<string>your-anon-key-here</string>
<key>OpenWeatherAPIKey</key>
<string>your-api-key-here</string>
```

**Option 3: Using .xcconfig File**

Create `Config.xcconfig` in the project root:

```xcconfig
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your_supabase_anon_key
OPENWEATHER_API_KEY = your_openweather_api_key
```

Then in Xcode:
1. Go to Project Settings > Info tab
2. Under "Configurations", set Config.xcconfig for Debug and Release

### 3. Get OpenWeatherMap API Key

1. Visit [OpenWeatherMap API](https://openweathermap.org/api)
2. Sign up for a free account
3. Go to "API Keys" section
4. Copy your API key
5. Add it to your environment variables (see step 2 above)

### 4. Build and Run

## Key Components

### SupabaseClient ([Core/Authentication/SupabaseClient.swift](Core/Authentication/SupabaseClient.swift))
Handles all Supabase database operations:
- Fetching favorite cities
- Adding/removing favorites
- Authentication token management
- Row Level Security (RLS) support

### CitySearchViewModel ([Features/CitySearch/ViewModels/CitySearchViewModel.swift](Features/CitySearch/ViewModels/CitySearchViewModel.swift))
Manages search and favorites state:
- City search with OpenWeatherMap Geocoding API
- Loading and displaying favorite cities
- Real-time search results with debouncing
- State management with `@Published` properties

### MainAppView ([App/MainAppView.swift](App/MainAppView.swift))
Main navigation and search interface:
- Search bar with real-time updates
- Favorites display
- Search results display
- Uses `@StateObject` for proper SwiftUI observation

## Technical Details

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### SwiftUI Best Practices
- **MVVM Architecture**: Clean separation of concerns
- **ObservableObject**: Reactive state management with Combine
- **Async/Await**: Modern concurrency for network calls
- **@StateObject**: Proper observation of ViewModels (not @State!)

### Data Persistence
- Supabase for favorite cities (cloud sync)
- UserDefaults for app settings
- Row Level Security (RLS) for data privacy

### Network Layer
- Modern async/await patterns
- Comprehensive error handling
- Type-safe API responses
- Debug logging for troubleshooting

## API Integration

### OpenWeatherMap
- **Geocoding API**: City search (http://api.openweathermap.org/geo/1.0/direct)
- **Current Weather API**: Real-time weather data
- **5 Day Forecast API**: Future weather predictions
- **Rate Limits**: Free tier - 60 calls/min, 1M calls/month

### Supabase
- **REST API**: Database operations via REST endpoints
- **Authentication**: Email/password auth with JWT tokens
- **RLS Policies**: User data isolation and security
- **Rate Limits**: Free tier - 500MB DB, 2GB bandwidth

## Troubleshooting

### Favorites Not Loading
**Symptoms**: Favorites don't appear when search page opens

**Solutions**:
1. Verify Supabase configuration:
   ```swift
   print(AppConfig.shared.supabaseConfigured) // Should be true
   ```
2. Check user is authenticated:
   ```swift
   print(authManager.accessToken) // Should not be nil
   ```
3. Verify RLS policies in Supabase dashboard
4. Check debug logs in Xcode console for:
   - 📡 Network requests
   - ✅ Success messages
   - ❌ Error details

### Search Results Not Appearing
**Symptoms**: Typing in search doesn't show results until location button pressed

**Solution**: This was a SwiftUI state management issue. Ensure `MainAppView.swift` uses:
```swift
@StateObject private var searchViewModel: CitySearchViewModel
```
NOT:
```swift
@State private var searchViewModel: CitySearchViewModel? // WRONG!
```

### "API key not found" Error
- Verify environment variables are set correctly
- Check AppConfig.swift is loading them properly
- Ensure keys are not wrapped in quotes
- Clean build folder (Cmd+Shift+K) and rebuild

### "Invalid Response" from Supabase
**Common causes**:
1. Missing or invalid access token
2. RLS policy blocking the request
3. Invalid table name
4. Network connectivity issues

**Debug**:
```swift
// Check SupabaseClient logs in console
print("📡 Fetching from table: favorite_cities")
print("📡 Response status: \(statusCode)")
```

### Build Errors
- Clean build folder: `Cmd+Shift+K`
- Delete derived data: `Shift+Cmd+K` then restart Xcode
- Verify all files are in Xcode project
- Check iOS deployment target is 17.0+

## Debug Logging

The app includes comprehensive debug logging with emoji prefixes:
- 📡 Network requests and responses
- 🔄 Loading states and data updates
- ✅ Successful operations
- ❌ Errors with detailed messages

View logs in Xcode console while app is running.

## Privacy & Permissions

Required permissions:
- **Location Services**: For current location weather
  - Add to Info.plist: `NSLocationWhenInUseUsageDescription`
- **Network Access**: For API calls (automatic)

## Security

- User data protected by Supabase Row Level Security (RLS)
- Access tokens required for all authenticated API calls
- Passwords never stored locally
- API keys stored securely in environment variables

## Known Issues

None currently. Previous search/favorites display issues have been resolved.

## Future Enhancements

Potential features:
- Hourly forecast view
- Weather radar maps
- Severe weather alerts
- Air quality index
- Weather widgets
- Push notifications for weather changes
- iCloud sync for settings
- Apple Watch companion app
- Weather sharing

## Contributing

When contributing to this project:
1. Follow MVVM architecture pattern
2. Use `@StateObject` for ViewModels, never `@State`
3. Add comprehensive debug logging
4. Handle all error cases gracefully
5. Read files before editing (use Read tool)
6. Test with real API calls

## Support

For issues:
- Check Troubleshooting section above
- Review debug logs in Xcode console
- Verify all environment variables are set
- See [CLAUDE.md](CLAUDE.md) for detailed technical context

## License

Copyright © 2026. All rights reserved.

## Credits

- Built with SwiftUI
- Weather data: OpenWeatherMap
- Backend: Supabase
- Architecture: MVVM with Combine
