# AniLedger

A macOS-native anime tracker application built with SwiftUI that integrates with AniList.co's GraphQL API.

## Features

- 📚 **Library Management**: Organize anime into Watching, Completed, Plan to Watch, On Hold, and Dropped lists
- 🔄 **AniList Sync**: Seamlessly sync your progress with AniList.co
- 🔍 **Discover & Search**: Browse seasonal anime, trending titles, and search for specific anime
- � **Seasonal Browser**: Explore anime by season (Winter, Spring, Summer, Fall) and year
- � **Progress Tracking**: Update episode progress with visual progress indicators
- 💾 **Offline Support**: View and edit your library offline with automatic sync when reconnected
- 🌐 **Network Monitoring**: Visual offline indicator when disconnected
- 🎨 **Native macOS UI**: Beautiful SwiftUI interface with light/dark mode support
- 🔐 **Secure Authentication**: OAuth2 flow with secure Keychain token storage
- 🖼️ **Image Caching**: Efficient image loading and caching for smooth performance
- 🔄 **Data Management**: Re-sync from AniList, clear local data, and automatic migration support

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later
- An AniList account (free at [anilist.co](https://anilist.co))

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/infinit3HQ/aniledger.git
cd AniLedger
```

### 2. Configure AniList OAuth

To use AniLedger, you need to register an OAuth application with AniList:

#### Step 1: Create an AniList API Client

1. Go to [AniList Developer Settings](https://anilist.co/settings/developer)
2. Log in with your AniList account
3. Click **"Create New Client"**

#### Step 2: Configure Your API Client

Fill in the following information:

- **Name**: `AniLedger` (or any name you prefer)
- **Redirect URI**: `aniledger://auth-callback`
- **Description**: (optional) "macOS anime tracker application"

Click **"Save"** to create your client.

#### Step 3: Copy Your Credentials

After creating the client, you'll see your **Client ID** and **Client Secret** displayed. 

**Important:** Copy **both** the Client ID and Client Secret. AniList requires the Client Secret for the OAuth token exchange step.

#### Step 4: Configure Your Credentials

Choose one of the following methods to securely configure your credentials:

**Method 1: Automated Setup Script (Recommended)**

Run the setup script and follow the prompts:

```bash
./setup.sh
```

The script will guide you through configuring your credentials in Xcode.

**Method 2: Xcode Environment Variables (Manual)**

1. In Xcode, go to: **Product → Scheme → Edit Scheme...**
2. Select **"Run"** in the left sidebar
3. Go to the **"Arguments"** tab
4. Under **"Environment Variables"**, click the **"+"** button
5. Add two variables:
   - **Name**: `ANILIST_CLIENT_ID`, **Value**: Your actual Client ID
   - **Name**: `ANILIST_CLIENT_SECRET`, **Value**: Your actual Client Secret
6. Click **"Close"**

**Method 3: .env File**

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```
2. Edit `.env` and replace the placeholder values with your actual credentials
3. Source the file before opening Xcode:
   ```bash
   source .env && open AniLedger.xcodeproj
   ```

The `.env` file is gitignored and will not be committed to version control.

### Security Note: About Client Secret

AniList requires both Client ID and Client Secret for OAuth token exchange. While native applications cannot perfectly secure secrets (they can be extracted through reverse engineering), AniList's OAuth implementation requires the Client Secret for the token exchange step. This is a limitation of AniList's OAuth flow, not a design choice.

**Best Practices:**
- Never commit credentials to version control
- Use environment variables for configuration
- Rotate credentials if they are exposed
- The `.env` file and Xcode scheme files are gitignored for your protection

### 3. Build and Run

1. Open `AniLedger.xcodeproj` in Xcode
2. Select your target device (My Mac)
3. Press `Cmd + R` to build and run the application

### 4. First Launch

1. When you first launch AniLedger, you'll see a login screen
2. Click **"Login with AniList"**
3. You'll be redirected to AniList in your default browser
4. Authorize the application
5. You'll be redirected back to AniLedger automatically
6. Your anime lists will sync from AniList

**Quick Start:** For a faster setup process, see [QUICK_START.md](QUICK_START.md)

## Configuration

### App Settings

You can customize AniLedger's behavior in the Settings view:

- **Auto-Sync**: Enable/disable automatic synchronization with AniList (syncs every 15 minutes)
- **Theme**: Choose between Light, Dark, or System theme
- **Account**: View your AniList profile information
- **Data Management**: Re-sync from AniList or clear local data
- **Logout**: Sign out with optional data clearing

### Data Management Features

AniLedger includes robust data management capabilities:

- **Automatic Migration**: Seamless Core Data schema updates with automatic lightweight migration
- **Migration Recovery**: Automatic recovery from corrupted data or failed migrations
- **Re-sync from AniList**: Manually trigger a complete re-sync if data becomes corrupted
- **Clear Local Data**: Remove all cached anime data while keeping your account logged in
- **Clear on Logout**: Optional data clearing when logging out (configurable in Settings)

### Advanced Configuration

Advanced users can modify additional settings in `AniLedger/Config.swift`:

```swift
// Sync Configuration
static let autoSyncInterval: TimeInterval = 15 * 60  // Sync interval in seconds
static let maxSyncRetries = 3                        // Max retry attempts
static let syncRetryDelay: TimeInterval = 5          // Delay between retries

// Cache Configuration
static let imageCacheMemoryLimit = 50 * 1024 * 1024  // 50 MB
static let imageCacheDiskLimit = 200 * 1024 * 1024   // 200 MB
static let imageCacheExpiration: TimeInterval = 7 * 24 * 60 * 60  // 7 days

// UI Configuration
static let discoverPageSize = 50                     // Items per page in Discover
static let searchResultsLimit = 20                   // Search results limit
static let searchDebounceDelay: TimeInterval = 0.5   // Search input debounce
```

## Architecture

AniLedger follows the MVVM (Model-View-ViewModel) architecture pattern with a clean separation of concerns:

### Layers

- **Models**: Domain models (Anime, UserAnime, AniListUser, etc.)
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Business logic and state management
- **Services**: API client, authentication, sync, and data services
- **Core Data**: Local persistence layer with automatic migration support
- **GraphQL**: Query and mutation definitions for AniList API

### Key Components

- **AuthenticationService**: OAuth2 flow, token management, and user authentication
- **AniListAPIClient**: GraphQL query/mutation execution with rate limiting
- **SyncService**: Bidirectional data synchronization between local and remote
- **AnimeService**: Local data operations with Core Data
- **KeychainManager**: Secure token storage using macOS Keychain
- **NetworkMonitor**: Real-time network connectivity monitoring
- **ImageCacheManager**: Efficient image loading and caching
- **CoreDataStack**: Core Data setup with automatic migration and recovery

### Design Patterns

- **Protocol-Oriented**: Services use protocols for testability and flexibility
- **Dependency Injection**: ViewModels receive dependencies via initializers
- **Async/Await**: Modern Swift concurrency for asynchronous operations
- **Combine**: Reactive programming for state management
- **Repository Pattern**: AnimeService abstracts data access

## Usage

### Navigation

AniLedger uses a sidebar navigation with the following sections:

- **Library**: Your personal anime collection organized by status
- **Discover**: Browse trending and popular anime
- **Seasons**: Explore anime by season and year
- **Search**: Find specific anime titles
- **Settings**: Configure app preferences and manage data

### Managing Your Library

- **View Lists**: Navigate to Library to see your anime organized by status (Watching, Completed, Plan to Watch, On Hold, Dropped)
- **Update Progress**: Click on an anime card to view details and update episode progress
- **Status Management**: Change anime status from the detail view
- **Visual Progress**: See progress bars showing episode completion
- **Sync Status**: Pull to refresh to manually sync with AniList

### Discovering Anime

- **Browse Trending**: Navigate to Discover to see trending and popular anime
- **Genre Filtering**: Use genre tags to filter anime by category
- **Format Filtering**: Filter by TV, Movie, OVA, etc.
- **Add to Library**: Click on an anime to view details and add to your library

### Seasonal Browser

- **Browse by Season**: Navigate to Seasons to explore anime by season (Winter, Spring, Summer, Fall)
- **Year Selection**: Browse anime from different years
- **Upcoming Anime**: See what's coming in future seasons
- **Quick Add**: Add anime directly from the seasonal view

### Searching

- **Real-time Search**: Navigate to Search and type an anime title
- **Debounced Input**: Search automatically updates as you type (with 0.5s delay)
- **Quick Add**: Click on a search result to view details and add to your library
- **Empty States**: Helpful messages when no results are found

### Offline Mode

- **Offline Support**: AniLedger works offline! All your data is stored locally
- **Automatic Sync**: Changes made offline will automatically sync when you reconnect
- **Visual Indicator**: An offline indicator banner appears when you're disconnected
- **Network Monitoring**: Real-time network status monitoring

## Troubleshooting

### Authentication Issues

**Problem**: "Client ID not configured" warning on launch

**Solutions**:
- Verify your environment variables are set correctly
- Check Xcode scheme: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
- Ensure both `ANILIST_CLIENT_ID` and `ANILIST_CLIENT_SECRET` are set
- Try running the setup script: `./setup.sh`

**Problem**: "Authentication failed" error

**Solutions**:
- Verify your Client ID and Client Secret are correct
- Ensure the redirect URI in AniList settings matches exactly: `aniledger://auth-callback`
- Check that your AniList API client is active (not disabled)
- Try logging out and logging in again

### Sync Issues

**Problem**: Changes not syncing with AniList

**Solutions**:
- Check your internet connection (look for offline indicator)
- Verify you're logged in (check Settings → Account)
- Try manually syncing by pulling down in Library view
- Check if auto-sync is enabled in Settings
- Try "Re-sync from AniList" in Settings → Data Management

**Problem**: Data appears corrupted or out of sync

**Solutions**:
- Go to Settings → Data Management
- Click "Re-sync from AniList" to perform a complete re-sync
- This will destroy local data and fetch fresh data from AniList

### Performance Issues

**Problem**: App feels slow or unresponsive

**Solutions**:
- Clear local data: Settings → Data Management → Clear Local Data
- Check available disk space on your Mac
- Reduce cache limits in `Config.swift` if needed
- Restart the app

**Problem**: Images not loading or loading slowly

**Solutions**:
- Check your internet connection
- Image cache may be full - try clearing local data
- Adjust cache limits in `Config.swift`:
  - `imageCacheMemoryLimit` (default: 50 MB)
  - `imageCacheDiskLimit` (default: 200 MB)

### Data Issues

**Problem**: Core Data migration failed

**Solutions**:
- The app automatically recovers from migration failures
- If issues persist, use "Re-sync from AniList" in Settings
- Check Console.app for detailed error logs

## Development

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme AniLedger -destination 'platform=macOS'

# Run specific test suite
xcodebuild test -scheme AniLedger -destination 'platform=macOS' -only-testing:AniLedgerTests/AuthenticationServiceTests

# Using test scripts
./scripts/run-auth-service-tests.sh
./scripts/run-api-client-tests.sh
./scripts/run-anime-service-tests.sh
```

### Verification Scripts

```bash
# Verify service implementations
./scripts/verify-auth-service.sh
./scripts/verify-api-client.sh
./scripts/verify-anime-service.sh
```

### Project Structure

```
AniLedger/
├── Models/              # Domain models (Anime, UserAnime, etc.)
├── Views/               # SwiftUI views and reusable components
├── ViewModels/          # View models for business logic
├── Services/            # Service layer (API, Auth, Sync, etc.)
├── CoreData/            # Core Data stack and migration
├── GraphQL/             # GraphQL queries, mutations, and protocols
├── Utilities/           # Helper utilities and extensions
├── Assets.xcassets/     # Images, colors, and assets
├── Config.swift         # App configuration constants
└── Info.plist           # App configuration and URL schemes

AniLedgerTests/
├── Services/            # Service layer tests
├── ViewModels/          # ViewModel tests
└── Mocks/               # Mock objects for testing

scripts/
├── run-*-tests.sh       # Test execution scripts
└── verify-*.sh          # Verification scripts
```

### Key Files

- **Config.swift**: Central configuration for API, sync, cache, and UI settings
- **CoreDataStack.swift**: Core Data setup with automatic migration and recovery
- **AniListAPIClient.swift**: GraphQL API client with rate limiting
- **AuthenticationService.swift**: OAuth2 authentication flow
- **SyncService.swift**: Bidirectional data synchronization
- **NetworkMonitor.swift**: Real-time network connectivity monitoring

## Privacy & Security

AniLedger respects your privacy and security:

- **Secure Storage**: Authentication tokens are stored securely in macOS Keychain
- **No Analytics**: No analytics, tracking, or telemetry
- **Direct Sync**: All data syncs directly with AniList (no third-party servers)
- **Local First**: Your data is stored locally and you control when it syncs
- **Data Control**: Clear your data anytime from Settings
- **Open Source**: Code is transparent and auditable
- **Environment Variables**: Credentials never hardcoded in source code

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Development Guidelines

- Follow Swift best practices and conventions
- Write unit tests for new features
- Update documentation for significant changes
- Use SwiftUI for all UI components
- Follow the existing MVVM architecture pattern

## Documentation

- **[QUICK_START.md](QUICK_START.md)**: Fast setup guide (5 minutes)
- **[DATA_MIGRATION_AND_CLEANUP.md](AniLedger/CoreData/DATA_MIGRATION_AND_CLEANUP.md)**: Data management features
- **[REUSABLE_COMPONENTS_SUMMARY.md](AniLedger/Views/REUSABLE_COMPONENTS_SUMMARY.md)**: UI component documentation
- **[Services README](AniLedger/Services/README.md)**: Service layer documentation
- **[APP_INFORMATION_MANAGEMENT.md](AniLedger/Documentation/APP_INFORMATION_MANAGEMENT.md)**: App information and version management

## License

AniLedger is licensed under a **Non-Commercial Open Source License**.

**You are free to:**
- ✅ Use the software for personal, educational, or non-profit purposes
- ✅ Fork and modify the code
- ✅ Create and distribute open source versions
- ✅ Contribute to the project

**You may NOT:**
- ❌ Use the software for commercial purposes
- ❌ Sell the software or derivatives
- ❌ Create proprietary/closed-source versions
- ❌ Use in commercial products or services without permission

**Requirements:**
- All forks and modifications must remain open source
- You must retain attribution to the original authors
- Modified versions must be licensed under the same terms

For commercial licensing inquiries, please contact the project maintainers.

See the [LICENSE](LICENSE) file for full details.

## Acknowledgments

- [AniList](https://anilist.co) for providing the excellent GraphQL API
- Inspired by [Taiga](https://taiga.moe) anime tracker
- Built with SwiftUI and modern Swift concurrency

## Support

For issues or questions:
- Open an issue on GitHub
- Check the [AniList API documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)
- Review the troubleshooting section above

---

Made with ❤️ for the anime community
