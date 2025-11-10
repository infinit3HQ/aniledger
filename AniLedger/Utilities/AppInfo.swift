//
//  AppInfo.swift
//  AniLedger
//
//  Centralized app information management
//

import Foundation

/// Provides centralized access to app information from Info.plist and runtime
struct AppInfo {
    
    // MARK: - App Identity
    
    /// The app's bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.aniledger"
    }
    
    /// The app's display name
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "AniLedger"
    }
    
    // MARK: - Version Information
    
    /// The app's version string (e.g., "0.2.0")
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
    
    /// The app's build number
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    /// Combined version and build string (e.g., "0.2.0 (1)")
    static var fullVersion: String {
        "\(version) (\(buildNumber))"
    }
    
    // MARK: - Copyright & Legal
    
    /// Copyright notice
    static var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        ?? "Copyright © 2025 AniLedger (com.aniledger). All rights reserved."
    }
    
    // MARK: - System Requirements
    
    /// Minimum macOS version required
    static var minimumOSVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String ?? "12.0"
    }
    
    /// Current macOS version
    static var currentOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    // MARK: - App Category
    
    /// App category type
    static var categoryType: String {
        Bundle.main.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
        ?? "public.app-category.entertainment"
    }
    
    // MARK: - URLs & Links
    
    /// GitHub repository URL
    static let repositoryURL = URL(string: "https://github.com/infinit3HQ/aniledger")!
    
    /// AniList website URL
    static let aniListURL = URL(string: "https://anilist.co")!
    
    /// AniList API documentation URL
    static let apiDocumentationURL = URL(string: "https://anilist.gitbook.io/anilist-apiv2-docs/")!
    
    /// Support/Issues URL
    static let supportURL = URL(string: "https://github.com/infinit3HQ/aniledger/issues")!
    
    // MARK: - Developer Information
    
    /// Developer/Organization name
    static let developerName = "AniLedger"
    
    /// Developer website (if available)
    static let developerURL: URL? = nil
    
    // MARK: - App Description
    
    /// Short app description
    static let shortDescription = "A macOS-native anime tracker application"
    
    /// Full app description
    static let fullDescription = """
    AniLedger is a native macOS anime tracker that seamlessly integrates with AniList.co. \
    Track your anime progress, discover new shows, browse seasonal releases, and sync your \
    library across devices with a beautiful SwiftUI interface.
    """
    
    // MARK: - Features List
    
    /// List of key features
    static let features: [String] = [
        "Library Management",
        "AniList Sync",
        "Discover & Search",
        "Seasonal Browser",
        "Progress Tracking",
        "Offline Support",
        "Network Monitoring",
        "Native macOS UI",
        "Secure Authentication",
        "Image Caching",
        "Data Management",
        "Episode Notifications"
    ]
    
    // MARK: - License Information
    
    /// License type
    static let licenseType = "Non-Commercial Open Source"
    
    /// License summary
    static let licenseSummary = """
    AniLedger is licensed under a Non-Commercial Open Source License. \
    Free for personal, educational, and non-profit use. \
    Commercial use requires permission.
    """
    
    // MARK: - Helper Methods
    
    /// Check if the app is running in debug mode
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Check if the app is running in preview mode
    static var isPreviewMode: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    /// Get formatted app info for display
    static func formattedInfo() -> String {
        """
        \(appName) v\(fullVersion)
        \(copyright)
        
        Bundle ID: \(bundleIdentifier)
        macOS: \(currentOSVersion) (requires \(minimumOSVersion)+)
        Category: \(categoryType)
        
        \(shortDescription)
        """
    }
    
    /// Get app info dictionary for debugging
    static func debugInfo() -> [String: Any] {
        [
            "appName": appName,
            "bundleIdentifier": bundleIdentifier,
            "version": version,
            "buildNumber": buildNumber,
            "fullVersion": fullVersion,
            "copyright": copyright,
            "minimumOSVersion": minimumOSVersion,
            "currentOSVersion": currentOSVersion,
            "categoryType": categoryType,
            "isDebugMode": isDebugMode,
            "isPreviewMode": isPreviewMode
        ]
    }
}
