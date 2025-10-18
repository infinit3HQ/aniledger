//
//  CacheManager.swift
//  AniLedger
//
//  Manages in-memory caching of API responses
//

import Foundation

/// Cache manager for storing API responses in memory
class CacheManager {
    static let shared = CacheManager()
    
    private var cache: [String: CachedItem] = [:]
    private let queue = DispatchQueue(label: "com.aniledger.cache", attributes: .concurrent)
    
    private init() {}
    
    /// Cached item with expiration
    private struct CachedItem {
        let data: Any
        let timestamp: Date
        let expirationInterval: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expirationInterval
        }
    }
    
    /// Store data in cache with expiration time
    func set<T>(_ data: T, forKey key: String, expirationInterval: TimeInterval = 300) {
        queue.async(flags: .barrier) {
            self.cache[key] = CachedItem(
                data: data,
                timestamp: Date(),
                expirationInterval: expirationInterval
            )
        }
    }
    
    /// Retrieve data from cache if not expired
    func get<T>(forKey key: String) -> T? {
        queue.sync {
            guard let item = cache[key], !item.isExpired else {
                return nil
            }
            return item.data as? T
        }
    }
    
    /// Check if cache has valid data for key
    func hasValidCache(forKey key: String) -> Bool {
        queue.sync {
            guard let item = cache[key] else { return false }
            return !item.isExpired
        }
    }
    
    /// Clear specific cache entry
    func clear(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    /// Clear all cache
    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
    
    /// Remove expired items
    func cleanExpired() {
        queue.async(flags: .barrier) {
            self.cache = self.cache.filter { !$0.value.isExpired }
        }
    }
}

// MARK: - Cache Keys

extension CacheManager {
    enum CacheKey {
        static let currentSeason = "discover.currentSeason"
        static let upcoming = "discover.upcoming"
        static let trending = "discover.trending"
        static let userLists = "library.userLists"
        
        static func animeDetail(_ id: Int) -> String {
            "anime.detail.\(id)"
        }
    }
}
