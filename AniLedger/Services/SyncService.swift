//
//  SyncService.swift
//  AniLedger
//
//  Service for synchronizing anime data between local storage and AniList API
//

import Foundation
import CoreData

protocol SyncServiceProtocol {
    func syncAll() async throws
    func syncUserLists() async throws
    func processSyncQueue() async throws
    func queueOperation(_ operation: SyncOperation)
}

enum SyncOperation {
    case updateProgress(mediaId: Int, progress: Int, status: String?)
    case updateStatus(mediaId: Int, status: String)
    case deleteEntry(mediaId: Int)
}

class SyncService: SyncServiceProtocol {
    private let apiClient: AniListAPIClientProtocol
    private let coreDataStack: CoreDataStack
    private let animeService: AnimeServiceProtocol
    private let userIdProvider: () -> Int?
    private var connectionRestoredObserver: NSObjectProtocol?
    
    init(
        apiClient: AniListAPIClientProtocol,
        coreDataStack: CoreDataStack = .shared,
        animeService: AnimeServiceProtocol,
        userIdProvider: @escaping () -> Int?
    ) {
        self.apiClient = apiClient
        self.coreDataStack = coreDataStack
        self.animeService = animeService
        self.userIdProvider = userIdProvider
        
        // Listen for network connection restoration
        setupNetworkObserver()
    }
    
    deinit {
        if let observer = connectionRestoredObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNetworkObserver() {
        connectionRestoredObserver = NotificationCenter.default.addObserver(
            forName: .networkConnectionRestored,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                try? await self?.processSyncQueue()
            }
        }
    }
    
    // MARK: - Initial Sync
    
    /// Performs initial sync on login - fetches all user anime lists from AniList
    func syncAll() async throws {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw KiroError.networkError(underlying: NSError(
                domain: "SyncService",
                code: 3001,
                userInfo: [NSLocalizedDescriptionKey: "No network connection"]
            ))
        }
        
        guard let userId = userIdProvider() else {
            throw KiroError.authenticationFailed(reason: "User not authenticated")
        }
        
        // Fetch all anime lists from AniList
        let query = FetchUserAnimeListQuery(userId: userId, status: nil)
        let response: MediaListCollectionResponse = try await apiClient.execute(query: query)
        
        // Process all entries
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            for list in response.MediaListCollection.lists {
                for entry in list.entries {
                    try self.processRemoteEntry(entry, context: context)
                }
            }
            
            try context.save()
        }
    }
    
    // MARK: - Incremental Sync
    
    /// Performs incremental sync - fetches updates from AniList and merges with local changes
    func syncUserLists() async throws {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw KiroError.networkError(underlying: NSError(
                domain: "SyncService",
                code: 3001,
                userInfo: [NSLocalizedDescriptionKey: "No network connection"]
            ))
        }
        
        guard let userId = userIdProvider() else {
            throw KiroError.authenticationFailed(reason: "User not authenticated")
        }
        
        // Fetch all anime lists from AniList
        let query = FetchUserAnimeListQuery(userId: userId, status: nil)
        let response: MediaListCollectionResponse = try await apiClient.execute(query: query)
        
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            // Get all local user anime
            let localUserAnime = self.coreDataStack.fetchAllUserAnime(context: context)
            let localAnimeIds = Set(localUserAnime.map { Int($0.animeId) })
            
            // Track remote anime IDs
            var remoteAnimeIds = Set<Int>()
            
            // Process remote entries
            for list in response.MediaListCollection.lists {
                for entry in list.entries {
                    remoteAnimeIds.insert(entry.media.id)
                    try self.processRemoteEntry(entry, context: context)
                }
            }
            
            // Remove local entries that don't exist remotely (deleted on AniList)
            let deletedAnimeIds = localAnimeIds.subtracting(remoteAnimeIds)
            for animeId in deletedAnimeIds {
                if let userAnimeEntity = self.coreDataStack.fetchUserAnime(byAnimeId: Int64(animeId), context: context) {
                    // Only delete if it doesn't need sync (not a pending local change)
                    if !userAnimeEntity.needsSync {
                        context.delete(userAnimeEntity)
                    }
                }
            }
            
            try context.save()
        }
    }
    
    // MARK: - Sync Queue Processing
    
    /// Processes queued operations when connection is restored
    func processSyncQueue() async throws {
        // Check network connectivity - silently return if offline
        guard NetworkMonitor.shared.isConnected else {
            return
        }
        
        let context = coreDataStack.newBackgroundContext()
        
        let queueItems = await context.perform {
            self.coreDataStack.fetchSyncQueue(context: context)
        }
        
        for item in queueItems {
            let itemId = item.objectID
            do {
                try await processQueueItem(item, context: context)
                
                // Delete successfully processed item
                await context.perform {
                    if let itemToDelete = try? context.existingObject(with: itemId) as? SyncQueueEntity {
                        context.delete(itemToDelete)
                        try? context.save()
                    }
                }
            } catch {
                // Increment retry count
                await context.perform {
                    if let itemToUpdate = try? context.existingObject(with: itemId) as? SyncQueueEntity {
                        itemToUpdate.retryCount += 1
                        
                        // Remove item if max retries exceeded
                        if itemToUpdate.retryCount >= 5 {
                            context.delete(itemToUpdate)
                        }
                        
                        try? context.save()
                    }
                }
                
                // Continue processing other items
                continue
            }
        }
    }
    
    // MARK: - Queue Operation
    
    /// Queues an operation for later sync when offline
    func queueOperation(_ operation: SyncOperation) {
        let context = coreDataStack.viewContext
        
        let queueItem = SyncQueueEntity(context: context)
        queueItem.id = UUID()
        queueItem.createdAt = Date()
        queueItem.retryCount = 0
        
        switch operation {
        case .updateProgress(let mediaId, let progress, let status):
            queueItem.operation = "updateProgress"
            queueItem.entityType = "UserAnime"
            queueItem.entityId = Int64(mediaId)
            
            let payload: [String: Any] = [
                "mediaId": mediaId,
                "progress": progress,
                "status": status as Any
            ]
            queueItem.payload = try? JSONSerialization.data(withJSONObject: payload).base64EncodedString()
            
        case .updateStatus(let mediaId, let status):
            queueItem.operation = "updateStatus"
            queueItem.entityType = "UserAnime"
            queueItem.entityId = Int64(mediaId)
            
            let payload: [String: Any] = [
                "mediaId": mediaId,
                "status": status
            ]
            queueItem.payload = try? JSONSerialization.data(withJSONObject: payload).base64EncodedString()
            
        case .deleteEntry(let mediaId):
            queueItem.operation = "deleteEntry"
            queueItem.entityType = "UserAnime"
            queueItem.entityId = Int64(mediaId)
            
            let payload: [String: Any] = ["mediaId": mediaId]
            queueItem.payload = try? JSONSerialization.data(withJSONObject: payload).base64EncodedString()
        }
        
        try? coreDataStack.saveContext()
    }
    
    // MARK: - Private Helper Methods
    
    private func processRemoteEntry(_ entry: MediaListEntry, context: NSManagedObjectContext) throws {
        // Create or update anime entity
        let anime = convertToAnime(from: entry.media)
        let animeEntity = try fetchOrCreateAnimeEntity(from: anime, context: context)
        
        // Check if user anime exists locally
        if let existingUserAnime = coreDataStack.fetchUserAnime(byAnimeId: Int64(entry.media.id), context: context) {
            // Conflict resolution: remote wins unless local has pending changes
            if existingUserAnime.needsSync {
                // Local has pending changes - keep local data
                // The pending changes will be synced via sync queue
                return
            } else {
                // Update with remote data
                existingUserAnime.status = entry.status
                existingUserAnime.progress = Int32(entry.progress)
                existingUserAnime.score = entry.score ?? 0.0
                existingUserAnime.needsSync = false
                existingUserAnime.lastModified = Date()
            }
        } else {
            // Create new user anime entry
            let userAnimeEntity = UserAnimeEntity(context: context)
            userAnimeEntity.id = Int64(entry.id)
            userAnimeEntity.animeId = Int64(entry.media.id)
            userAnimeEntity.status = entry.status
            userAnimeEntity.progress = Int32(entry.progress)
            userAnimeEntity.score = entry.score ?? 0.0
            userAnimeEntity.sortOrder = 0 // Will be reordered later
            userAnimeEntity.needsSync = false
            userAnimeEntity.lastModified = Date()
            userAnimeEntity.anime = animeEntity
        }
    }
    
    private func processQueueItem(_ item: SyncQueueEntity, context: NSManagedObjectContext) async throws {
        guard let payloadString = item.payload,
              let payloadData = Data(base64Encoded: payloadString),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw KiroError.decodingError(underlying: NSError(
                domain: "SyncService",
                code: 2001,
                userInfo: [NSLocalizedDescriptionKey: "Invalid queue item payload"]
            ))
        }
        
        switch item.operation {
        case "updateProgress":
            guard let mediaId = payload["mediaId"] as? Int,
                  let progress = payload["progress"] as? Int else {
                throw KiroError.decodingError(underlying: NSError(
                    domain: "SyncService",
                    code: 2002,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid updateProgress payload"]
                ))
            }
            
            let status = payload["status"] as? String
            let mutation = UpdateProgressMutation(mediaId: mediaId, progress: progress, status: status)
            let _: SaveMediaListEntryResponse = try await apiClient.execute(mutation: mutation)
            
            // Update local needsSync flag
            await context.perform {
                if let userAnime = self.coreDataStack.fetchUserAnime(byAnimeId: Int64(mediaId), context: context) {
                    userAnime.needsSync = false
                    try? context.save()
                }
            }
            
        case "updateStatus":
            guard let mediaId = payload["mediaId"] as? Int,
                  let status = payload["status"] as? String else {
                throw KiroError.decodingError(underlying: NSError(
                    domain: "SyncService",
                    code: 2003,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid updateStatus payload"]
                ))
            }
            
            let mutation = UpdateStatusMutation(mediaId: mediaId, status: status)
            let _: SaveMediaListEntryResponse = try await apiClient.execute(mutation: mutation)
            
            // Update local needsSync flag
            await context.perform {
                if let userAnime = self.coreDataStack.fetchUserAnime(byAnimeId: Int64(mediaId), context: context) {
                    userAnime.needsSync = false
                    try? context.save()
                }
            }
            
        case "deleteEntry":
            // AniList doesn't have a delete mutation, so we just remove from local
            // The entry will be removed during next sync if it doesn't exist remotely
            break
            
        default:
            throw KiroError.apiError(message: "Unknown operation type", statusCode: nil)
        }
    }
    
    private func fetchOrCreateAnimeEntity(from anime: Anime, context: NSManagedObjectContext) throws -> AnimeEntity {
        // Try to fetch existing anime
        if let existing = coreDataStack.fetchAnime(byId: Int64(anime.id), context: context) {
            // Update existing anime data
            existing.titleRomaji = anime.title.romaji
            existing.titleEnglish = anime.title.english
            existing.titleNative = anime.title.native
            existing.coverImageLarge = anime.coverImage.large
            existing.coverImageMedium = anime.coverImage.medium
            existing.episodes = Int32(anime.episodes ?? 0)
            existing.format = anime.format.rawValue
            existing.synopsis = anime.synopsis
            existing.siteUrl = anime.siteUrl
            existing.lastSynced = Date()
            
            // Update genres
            existing.genres = NSSet(array: anime.genres.map { genreName in
                coreDataStack.fetchOrCreateGenre(name: genreName, context: context)
            })
            
            return existing
        }
        
        // Create new anime entity
        let animeEntity = AnimeEntity(context: context)
        animeEntity.id = Int64(anime.id)
        animeEntity.titleRomaji = anime.title.romaji
        animeEntity.titleEnglish = anime.title.english
        animeEntity.titleNative = anime.title.native
        animeEntity.coverImageLarge = anime.coverImage.large
        animeEntity.coverImageMedium = anime.coverImage.medium
        animeEntity.episodes = Int32(anime.episodes ?? 0)
        animeEntity.format = anime.format.rawValue
        animeEntity.synopsis = anime.synopsis
        animeEntity.siteUrl = anime.siteUrl
        animeEntity.lastSynced = Date()
        
        // Add genres
        animeEntity.genres = NSSet(array: anime.genres.map { genreName in
            coreDataStack.fetchOrCreateGenre(name: genreName, context: context)
        })
        
        return animeEntity
    }
    
    private func convertToAnime(from media: MediaResponse) -> Anime {
        let title = AnimeTitle(
            romaji: media.title.romaji,
            english: media.title.english,
            native: media.title.native
        )
        
        let coverImage = CoverImage(
            large: media.coverImage.large,
            medium: media.coverImage.medium
        )
        
        let format = AnimeFormat(rawValue: media.format ?? "") ?? .tv
        
        return Anime(
            id: media.id,
            title: title,
            coverImage: coverImage,
            episodes: media.episodes,
            format: format,
            genres: media.genres,
            synopsis: media.description,
            siteUrl: media.siteUrl
        )
    }
}
