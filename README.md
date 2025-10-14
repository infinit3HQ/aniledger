# AniLedger

A macOS-native anime tracker application built with SwiftUI that integrates with AniList.co's GraphQL API.

## Features

- 📚 **Library Management**: Organize anime into Watching, Completed, Plan to Watch, On Hold, and Dropped lists
- 🔄 **AniList Sync**: Seamlessly sync your progress with AniList.co
- 🔍 **Discover & Search**: Browse seasonal, trending anime and search for titles
- 📊 **Progress Tracking**: Easily update episode progress with quick actions
- 💾 **Offline Support**: View and edit your library offline with automatic sync when reconnected
- 🎨 **Native macOS UI**: Beautiful SwiftUI interface with light/dark mode support

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- An AniList account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
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

#### Step 3: Copy Your Client ID

After creating the client, you'll see your **Client ID** and **Client Secret** displayed. 

**Important:** Copy only the **Client ID**. Do NOT use the Client Secret for this native application (see Security Note below).

#### Step 4: Configure Your Client ID

**⚠️ IMPORTANT: Do NOT hardcode your Client ID in Config.swift if you plan to make this repository public!**

Choose one of the following methods to securely configure your Client ID:

**Method 1: Xcode Environment Variable (Recommended)**

1. In Xcode, go to: **Product → Scheme → Edit Scheme...**
2. Select **"Run"** in the left sidebar
3. Go to the **"Arguments"** tab
4. Under **"Environment Variables"**, click the **"+"** button
5. Add a new variable:
   - **Name**: `ANILIST_CLIENT_ID`
   - **Value**: Your actual Client ID (e.g., `12345`)
6. Click **"Close"**

**Method 2: Terminal Environment Variable**

If you're running from the terminal:

```bash
export ANILIST_CLIENT_ID="your_actual_client_id"
open AniLedger.xcodeproj
```

**Method 3: .env File**

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```
2. Edit `.env` and replace `YOUR_CLIENT_ID_HERE` with your actual Client ID
3. Source the file before opening Xcode:
   ```bash
   source .env && open AniLedger.xcodeproj
   ```

The `.env` file is gitignored and will not be committed to version control.

### Security Note: Why No Client Secret?

AniList provides both a Client ID and Client Secret, but **AniLedger only uses the Client ID**. This is the correct and secure approach for native/desktop applications because:

- **Native apps cannot keep secrets secure**: Any secret in the app binary can be extracted through reverse engineering
- **No additional security**: Using a client secret in a native app doesn't provide real security benefits
- **OAuth best practice**: The Authorization Code flow works securely without client secret for native apps
- **AniList supports this**: AniList's OAuth implementation is designed to work this way

Client secrets are only appropriate for server-side applications where they can be kept truly secret.

### 3. Build and Run

1. Open `AniLedger.xcodeproj` in Xcode
2. Select your target device (Mac)
3. Press `Cmd + R` to build and run the application

### 4. First Launch

1. When you first launch AniLedger, you'll see a login screen
2. Click **"Login with AniList"**
3. You'll be redirected to AniList in your browser
4. Authorize the application
5. You'll be redirected back to AniLedger automatically
6. Your anime lists will sync from AniList

## Configuration

### App Settings

You can customize AniLedger's behavior in the Settings view:

- **Auto-Sync**: Enable/disable automatic synchronization with AniList (syncs every 15 minutes)
- **Theme**: Choose between Light, Dark, or System theme
- **Account**: View your AniList profile and logout

### Advanced Configuration

Advanced users can modify additional settings in `AniLedger/Config.swift`:

```swift
// Sync Configuration
static let autoSyncInterval: TimeInterval = 15 * 60  // Sync interval in seconds
static let maxSyncRetries = 3                        // Max retry attempts

// Cache Configuration
static let imageCacheMemoryLimit = 50 * 1024 * 1024  // 50 MB
static let imageCacheDiskLimit = 200 * 1024 * 1024   // 200 MB

// UI Configuration
static let discoverPageSize = 50                     // Items per page in Discover
static let searchResultsLimit = 20                   // Search results limit
```

## Architecture

AniLedger follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Domain models for Anime, UserAnime, etc.
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Business logic and state management
- **Services**: API client, authentication, sync, and data services
- **Core Data**: Local persistence layer

### Key Components

- **AuthenticationService**: Handles OAuth2 flow and token management
- **AniListAPIClient**: GraphQL query/mutation execution
- **SyncService**: Coordinates data synchronization between local and remote
- **AnimeService**: Local data operations with Core Data
- **KeychainManager**: Secure token storage

## Usage

### Managing Your Library

- **View Lists**: Navigate to Library to see your anime organized by status
- **Move Anime**: Drag and drop anime between lists to change status
- **Reorder**: Drag anime within a list to customize order
- **Update Progress**: Click on an anime to open details and update episode progress
- **Delete**: Swipe left on an anime to delete it from your library

### Discovering Anime

- **Browse**: Navigate to Discover to see seasonal, upcoming, and trending anime
- **Filter**: Use genre and format filters to narrow down results
- **Add to Library**: Click on an anime and select "Add to Library" to start tracking

### Searching

- **Search**: Navigate to Search and type an anime title
- **Quick Add**: Click on a search result to view details and add to your library

### Offline Mode

- AniLedger works offline! All your data is stored locally
- Changes made offline will automatically sync when you reconnect
- An offline indicator appears when you're disconnected

## Troubleshooting

### Authentication Issues

**Problem**: "Authentication failed" error

**Solutions**:
- Verify your Client ID is correct in `Config.swift`
- Ensure the redirect URI in AniList settings matches: `aniledger://auth-callback`
- Try logging out and logging in again

### Sync Issues

**Problem**: Changes not syncing with AniList

**Solutions**:
- Check your internet connection
- Verify you're logged in (check Settings)
- Try manually syncing by pulling down in Library view
- Check if auto-sync is enabled in Settings

### Performance Issues

**Problem**: App feels slow or unresponsive

**Solutions**:
- Clear image cache by logging out and back in
- Reduce cache limits in `Config.swift`
- Check available disk space

## Development

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme AniLedger -destination 'platform=macOS'

# Run specific test suite
xcodebuild test -scheme AniLedger -destination 'platform=macOS' -only-testing:AniLedgerTests/AuthenticationServiceTests
```

### Project Structure

```
AniLedger/
├── Models/              # Domain models
├── Views/               # SwiftUI views
├── ViewModels/          # View models
├── Services/            # Business logic services
├── CoreData/            # Core Data stack
├── GraphQL/             # GraphQL queries and mutations
├── Assets.xcassets/     # Images and colors
└── Config.swift         # App configuration

AniLedgerTests/
├── Services/            # Service tests
├── ViewModels/          # ViewModel tests
└── Mocks/               # Mock objects for testing
```

## Privacy

AniLedger respects your privacy:

- Only stores data necessary for functionality
- Authentication tokens are stored securely in macOS Keychain
- No analytics or tracking
- All data syncs directly with AniList (no third-party servers)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

[Add your license here]

## Acknowledgments

- [AniList](https://anilist.co) for providing the GraphQL API
- Inspired by [Taiga](https://taiga.moe) anime tracker

## Support

For issues or questions:
- Open an issue on GitHub
- Check the [AniList API documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)

---

Made with ❤️ for the anime community
