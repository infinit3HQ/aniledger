//
//  ImageCacheManager.swift
//  AniLedger
//
//  Manager for configuring and managing image caching using URLCache
//

import Foundation

/// Manager for image caching configuration and operations
class ImageCacheManager {
    
    // MARK: - Singleton
    
    static let shared = ImageCacheManager()
    
    // MARK: - Cache Configuration
    
    /// Memory capacity for image cache - using Config constant
    private let memoryCapacity = Config.imageCacheMemoryLimit
    
    /// Disk capacity for image cache - using Config constant
    private let diskCapacity = Config.imageCacheDiskLimit
    
    // MARK: - Initialization
    
    private init() {
        configureCache()
    }
    
    // MARK: - Configuration
    
    /// Configure URLCache with appropriate memory and disk limits
    func configureCache() {
        // An absolute directory is required: a relative diskPath is resolved
        // against the working directory, which is "/" (not writable) when the
        // app is opened from Finder, so images were never cached on disk.
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let directory = cachesDirectory?
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.aniledger", isDirectory: true)
            .appendingPathComponent("image_cache", isDirectory: true)
        
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            directory: directory
        )
        
        URLCache.shared = cache
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached images
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// Clear cached response for a specific URL
    /// - Parameter url: The URL to clear from cache
    func clearCache(for url: URL) {
        let request = URLRequest(url: url)
        URLCache.shared.removeCachedResponse(for: request)
    }
    
    /// Get current cache usage statistics
    /// - Returns: Tuple containing current memory and disk usage in bytes
    func getCacheUsage() -> (memoryUsage: Int, diskUsage: Int) {
        return (
            memoryUsage: URLCache.shared.currentMemoryUsage,
            diskUsage: URLCache.shared.currentDiskUsage
        )
    }
}
