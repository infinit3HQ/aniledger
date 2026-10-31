//
//  Config.swift
//  AniLedger
//
//  Configuration constants for the AniLedger app
//

import Foundation

enum Config {
    // MARK: - AniList OAuth Configuration
    
    /// Placeholder used when no client ID has been configured.
    static let clientIdPlaceholder = "YOUR_CLIENT_ID_HERE"

    /// AniList OAuth Client ID
    ///
    /// AniLedger uses AniList's implicit grant, which needs only the client ID.
    /// The client ID is not a secret (it appears in the login URL), so no
    /// client secret is shipped with the app.
    ///
    /// Resolution order:
    /// 1. `ANILIST_CLIENT_ID` environment variable (Xcode scheme, for development runs)
    /// 2. `AniListClientID` key in the app's Info.plist (injected by `scripts/build-dmg.sh`)
    ///
    /// The AniList API client must have its redirect URI set to `aniledger://auth-callback`.
    static var aniListClientId: String {
        if let envClientId = ProcessInfo.processInfo.environment["ANILIST_CLIENT_ID"],
           isValidClientId(envClientId) {
            return envClientId.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let bundledClientId = Bundle.main.object(forInfoDictionaryKey: "AniListClientID") as? String,
           isValidClientId(bundledClientId) {
            return bundledClientId.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return clientIdPlaceholder
    }

    /// Whether a usable client ID is available.
    static var isClientIdConfigured: Bool {
        aniListClientId != clientIdPlaceholder
    }

    private static func isValidClientId(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != clientIdPlaceholder && !trimmed.hasPrefix("$(")
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
        guard isClientIdConfigured else {
            print("Warning: AniList Client ID not configured. Set ANILIST_CLIENT_ID (see README).")
            return false
        }
        return true
    }
}
