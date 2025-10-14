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
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "image_cache"
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
