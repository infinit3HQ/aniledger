//
//  Config.swift
//  AniLedger
//
//  Configuration constants for the AniLedger app
//

import Foundation

enum Config {
    // MARK: - AniList OAuth Configuration
    
    /// AniList OAuth Client ID
    /// 
    /// **⚠️ SECURITY: DO NOT hardcode your client ID in this file for public repositories!**
    ///
    /// This value should be provided via environment variable to keep it secure.
    ///
    /// **Setup Instructions:**
    /// 
    /// **Method 1 - Xcode Environment Variable (Recommended for Development):**
    /// 1. In Xcode, go to: Product → Scheme → Edit Scheme...
    /// 2. Select "Run" on the left sidebar
    /// 3. Go to the "Arguments" tab
    /// 4. Under "Environment Variables", click the "+" button
    /// 5. Add: Name = `ANILIST_CLIENT_ID`, Value = `your_actual_client_id`
    /// 6. Click "Close"
    ///
    /// **Method 2 - Shell Environment Variable (For Terminal/CI):**
    /// ```bash
    /// export ANILIST_CLIENT_ID="your_actual_client_id"
    /// ```
    ///
    /// **Method 3 - .env file (Alternative):**
    /// 1. Create a `.env` file in the project root (it's gitignored)
    /// 2. Add: `ANILIST_CLIENT_ID=your_actual_client_id`
    /// 3. Source it before running: `source .env && open AniLedger.xcodeproj`
    /// 
    /// **Get Your Client ID:**
    /// 1. Go to https://anilist.co/settings/developer
    /// 2. Create a new API Client
    /// 3. Set the redirect URI to: `aniledger://auth-callback`
    /// 4. Copy the Client ID (NOT the Client Secret - see note below)
    ///
    /// **Note about Client Secret:**
    /// AniList provides both a Client ID and Client Secret when you create an API client.
    /// However, for native/desktop applications like AniLedger, you should ONLY use the Client ID.
    /// 
    /// Why we don't use Client Secret:
    /// - Native apps cannot securely store secrets (they can be extracted via reverse engineering)
    /// - AniList's OAuth works without client secret for native apps using Authorization Code flow
    /// - Client secrets are only for server-side applications where they can be kept secure
    /// - Using client secret in a native app provides no additional security
    ///
    /// The current implementation correctly uses only the Client ID.
    static var aniListClientId: String {
        // Read from environment variable
        if let envClientId = ProcessInfo.processInfo.environment["ANILIST_CLIENT_ID"],
           !envClientId.isEmpty,
           envClientId != "YOUR_CLIENT_ID_HERE" {
            return envClientId
        }
        
        // Fallback placeholder (will trigger validation warning)
        // DO NOT replace this with your actual client ID in a public repository!
        return "YOUR_CLIENT_ID_HERE"
    }
    
    /// OAuth Redirect URI - must match the one registered in AniList developer settings
    static let redirectUri = "aniledger://auth-callback"
    
    /// AniList OAuth authorization URL
    static let authorizationUrl = "https://anilist.co/api/v2/oauth/authorize"
    
    // MARK: - API Configuration
    
    /// AniList GraphQL API endpoint
    static let apiEndpoint = "https://graphql.anilist.co"
    
    /// API rate limit (requests per minute)
    static let rateLimitPerMinute = 90
    
    /// Request timeout interval in seconds
    static let requestTimeout: TimeInterval = 30
    
    // MARK: - Sync Configuration
    
    /// Interval for automatic sync when auto-sync is enabled (in seconds)
    static let autoSyncInterval: TimeInterval = 15 * 60 // 15 minutes
    
    /// Maximum number of retry attempts for failed sync operations
    static let maxSyncRetries = 3
    
    /// Delay between sync retries (in seconds)
    static let syncRetryDelay: TimeInterval = 5
    
    /// Time to wait before considering data stale (in seconds)
    static let dataStaleThreshold: TimeInterval = 60 * 60 // 1 hour
    
    // MARK: - Cache Configuration
    
    /// Memory cache size for images (in bytes)
    static let imageCacheMemoryLimit = 50 * 1024 * 1024 // 50 MB
    
    /// Disk cache size for images (in bytes)
    static let imageCacheDiskLimit = 200 * 1024 * 1024 // 200 MB
    
    /// Image cache expiration time (in seconds)
    static let imageCacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - UI Configuration
    
    /// Number of items to display per page in Discover section
    static let discoverPageSize = 50
    
    /// Number of search results to display
    static let searchResultsLimit = 20
    
    /// Debounce delay for search input (in seconds)
    static let searchDebounceDelay: TimeInterval = 0.5
    
    /// Animation duration for UI transitions (in seconds)
    static let animationDuration: TimeInterval = 0.3
    
    // MARK: - Keychain Configuration
    
    /// Keychain service identifier
    static let keychainService = "com.aniledger"
    
    /// Keychain access token key
    static let keychainAccessTokenKey = "accessToken"
    
    // MARK: - UserDefaults Keys
    
    enum UserDefaultsKeys {
        static let autoSyncEnabled = "autoSyncEnabled"
        static let themePreference = "themePreference"
        static let lastSyncDate = "lastSyncDate"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
    
    // MARK: - Core Data Configuration
    
    /// Core Data model name
    static let coreDataModelName = "AniLedger"
    
    /// Batch size for Core Data fetch requests
    static let fetchBatchSize = 20
    
    // MARK: - Validation
    
    /// Validates that the configuration is properly set up
    static func validate() -> Bool {
        guard aniListClientId != "YOUR_CLIENT_ID_HERE" else {
            print("⚠️ Warning: AniList Client ID not configured. Please update Config.swift with your client ID.")
            return false
        }
        return true
    }
}
