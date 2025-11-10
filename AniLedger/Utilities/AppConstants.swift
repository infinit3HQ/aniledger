//
//  AppConstants.swift
//  AniLedger
//
//  Application-wide constants and metadata
//

import Foundation

/// Application-wide constants
enum AppConstants {
    
    // MARK: - App Metadata
    
    enum Metadata {
        static let appName = "AniLedger"
        static let bundleIdentifier = "com.aniledger"
        static let urlScheme = "aniledger"
        static let developer = "Niraj Dilshan"
    }
    
    // MARK: - External URLs
    
    enum URLs {
        static let github = "https://github.com/infinit3HQ/aniledger"
        static let aniList = "https://anilist.co"
        static let aniListAPI = "https://graphql.anilist.co"
        static let aniListDocs = "https://anilist.gitbook.io/anilist-apiv2-docs/"
        static let aniListDeveloper = "https://anilist.co/settings/developer"
        static let issues = "https://github.com/infinit3HQ/aniledger/issues"
        static let releases = "https://github.com/infinit3HQ/aniledger/releases"
    }
    
    // MARK: - Feature Flags
    
    enum Features {
        static let notificationsEnabled = true
        static let offlineSupportEnabled = true
        static let autoSyncEnabled = true
        static let imageCachingEnabled = true
        static let networkMonitoringEnabled = true
    }
    
    // MARK: - UI Constants
    
    enum UI {
        // Window sizes
        static let aboutWindowWidth: CGFloat = 500
        static let aboutWindowHeight: CGFloat = 600
        static let releaseNotesWindowWidth: CGFloat = 600
        static let releaseNotesWindowHeight: CGFloat = 700
        static let notificationSettingsWidth: CGFloat = 500
        static let notificationSettingsHeight: CGFloat = 600
        
        // Sidebar
        static let sidebarMinWidth: CGFloat = 200
        static let sidebarIdealWidth: CGFloat = 220
        static let sidebarMaxWidth: CGFloat = 250
        
        // Grid layouts
        static let animeCardWidth: CGFloat = 180
        static let animeCardHeight: CGFloat = 280
        static let gridSpacing: CGFloat = 16
        
        // Images
        static let avatarSize: CGFloat = 60
        static let thumbnailSize: CGFloat = 120
        
        // Animations
        static let defaultAnimationDuration: Double = 0.3
        static let fastAnimationDuration: Double = 0.15
        static let slowAnimationDuration: Double = 0.5
    }
    
    // MARK: - Timing Constants
    
    enum Timing {
        // Sync intervals
        static let autoSyncInterval: TimeInterval = 15 * 60  // 15 minutes
        static let syncRetryDelay: TimeInterval = 5
        static let maxSyncRetries = 3
        
        // Search
        static let searchDebounceDelay: TimeInterval = 0.5
        
        // Cache
        static let imageCacheExpiration: TimeInterval = 7 * 24 * 60 * 60  // 7 days
        
        // Notifications
        static let notificationCheckInterval: TimeInterval = 60 * 60  // 1 hour
        static let defaultNotificationAdvance: TimeInterval = 30 * 60  // 30 minutes
    }
    
    // MARK: - Limits
    
    enum Limits {
        // API
        static let discoverPageSize = 50
        static let searchResultsLimit = 20
        static let maxConcurrentRequests = 5
        
        // Cache
        static let imageCacheMemoryLimit = 50 * 1024 * 1024  // 50 MB
        static let imageCacheDiskLimit = 200 * 1024 * 1024   // 200 MB
        
        // UI
        static let maxRecentSearches = 10
        static let maxNotificationHistory = 50
    }
    
    // MARK: - System Requirements
    
    enum Requirements {
        static let minimumMacOSVersion = "12.0"
        static let minimumMacOSName = "macOS Monterey"
        static let recommendedMacOSVersion = "13.0"
        static let recommendedMacOSName = "macOS Ventura"
    }
    
    // MARK: - Error Messages
    
    enum ErrorMessages {
        static let networkUnavailable = "Network connection unavailable. Please check your internet connection."
        static let authenticationFailed = "Authentication failed. Please try logging in again."
        static let syncFailed = "Failed to sync with AniList. Changes will be synced when connection is restored."
        static let dataCorrupted = "Local data appears to be corrupted. Please try re-syncing from AniList."
        static let unknownError = "An unexpected error occurred. Please try again."
    }
    
    // MARK: - Success Messages
    
    enum SuccessMessages {
        static let syncCompleted = "Successfully synced with AniList"
        static let dataCleared = "Local data cleared successfully"
        static let resyncCompleted = "Data re-synced from AniList"
        static let progressUpdated = "Progress updated"
        static let statusChanged = "Status changed"
    }
    
    // MARK: - Notification Identifiers
    
    enum NotificationIdentifiers {
        static let episodeAiring = "episode-airing"
        static let syncCompleted = "sync-completed"
        static let syncFailed = "sync-failed"
    }
    
    // MARK: - UserDefaults Keys
    
    enum UserDefaultsKeys {
        static let autoSyncEnabled = "autoSyncEnabled"
        static let themePreference = "themePreference"
        static let clearDataOnLogout = "clearDataOnLogout"
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationAdvanceTime = "notificationAdvanceTime"
        static let lastSyncDate = "lastSyncDate"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let appVersion = "appVersion"
    }
    
    // MARK: - Keychain Keys
    
    enum KeychainKeys {
        static let accessToken = "anilist_access_token"
        static let refreshToken = "anilist_refresh_token"
        static let userId = "anilist_user_id"
    }
    
    // MARK: - Core Data
    
    enum CoreData {
        static let modelName = "AniLedger"
        static let containerName = "AniLedger"
        static let storeFilename = "AniLedger.sqlite"
    }
    
    // MARK: - AniList API
    
    enum AniList {
        static let clientIdEnvKey = "ANILIST_CLIENT_ID"
        static let clientSecretEnvKey = "ANILIST_CLIENT_SECRET"
        static let redirectURI = "aniledger://auth-callback"
        static let authorizationURL = "https://anilist.co/api/v2/oauth/authorize"
        static let tokenURL = "https://anilist.co/api/v2/oauth/token"
        static let apiEndpoint = "https://graphql.anilist.co"
        
        // Rate limiting
        static let maxRequestsPerMinute = 90
        static let rateLimitWindow: TimeInterval = 60
    }
    
    // MARK: - Helper Methods
    
    /// Check if a feature is enabled
    static func isFeatureEnabled(_ feature: String) -> Bool {
        switch feature {
        case "notifications":
            return Features.notificationsEnabled
        case "offline":
            return Features.offlineSupportEnabled
        case "autoSync":
            return Features.autoSyncEnabled
        case "imageCache":
            return Features.imageCachingEnabled
        case "networkMonitoring":
            return Features.networkMonitoringEnabled
        default:
            return false
        }
    }
    
    /// Get user-friendly error message
    static func errorMessage(for error: Error) -> String {
        // Map specific errors to user-friendly messages
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return ErrorMessages.networkUnavailable
        } else if errorDescription.contains("auth") || errorDescription.contains("token") {
            return ErrorMessages.authenticationFailed
        } else if errorDescription.contains("sync") {
            return ErrorMessages.syncFailed
        } else if errorDescription.contains("corrupt") || errorDescription.contains("migration") {
            return ErrorMessages.dataCorrupted
        } else {
            return ErrorMessages.unknownError
        }
    }
}
