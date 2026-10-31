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
    case updateScore(mediaId: Int, score: Double)
    case deleteEntry(entryId: Int? = nil, mediaId: Int)
}

/// Serializes sync work. Callers wait their turn instead of being skipped,
/// so a manual refresh never silently does nothing because a background
/// queue flush happened to be running.
private actor SyncLock {
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    func acquire() async {
        guard isLocked else {
            isLocked = true
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func release() {
        if waiters.isEmpty {
            isLocked = false
        } else {
            // Hand the lock straight to the next waiter
            waiters.removeFirst().resume()
        }
    }
}

class SyncService: SyncServiceProtocol {
    private let apiClient: AniListAPIClientProtocol
    private let coreDataStack: CoreDataStack
    private let animeService: AnimeServiceProtocol
    private let userIdProvider: () -> Int?
    private let userLoader: (() async throws -> Void)?
    private var connectionRestoredObserver: NSObjectProtocol?
    private let syncLock = SyncLock()
    private var syncQueueTask: Task<Void, Never>?
    
    init(
        apiClient: AniListAPIClientProtocol,
        coreDataStack: CoreDataStack = .shared,
        animeService: AnimeServiceProtocol,
        userIdProvider: @escaping () -> Int?,
        userLoader: (() async throws -> Void)? = nil
    ) {
        self.apiClient = apiClient
        self.coreDataStack = coreDataStack
        self.animeService = animeService
        self.userIdProvider = userIdProvider
        self.userLoader = userLoader
        
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
            // Cancel any existing sync queue task
            self?.syncQueueTask?.cancel()
            
            // Create new task with debounce
            self?.syncQueueTask = Task {
                // Wait a bit to debounce multiple rapid calls
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                guard !Task.isCancelled else { return }
                
                try? await self?.processSyncQueue()
            }
        }
    }
    
    // MARK: - Sync Lock
    
    // Each public sync entry point waits for the lock, runs its work, and
    // releases the lock before returning. Calls run one after another.

    func syncAll() async throws {
        await syncLock.acquire()
        do {
            try await performSyncAll()
        } catch {
            await syncLock.release()
            throw error
        }
        await syncLock.release()
    }

    func syncUserLists() async throws {
        await syncLock.acquire()
        do {
            try await performSyncUserLists()
        } catch {
            await syncLock.release()
            throw error
        }
        await syncLock.release()
    }

    func processSyncQueue() async throws {
        await syncLock.acquire()
        do {
            try await performProcessSyncQueue()
        } catch {
            await syncLock.release()
            throw error
        }
        await syncLock.release()
    }
    
    /// The signed-in user's AniList ID. Loads the profile first if it isn't
    /// available yet (e.g. the app launched offline), instead of failing with
    /// "User not authenticated" until the next launch.
    private func resolveUserId() async throws -> Int {
        if let userId = userIdProvider() {
            return userId
        }
        try await userLoader?()
        guard let userId = userIdProvider() else {
            throw KiroError.authenticationFailed(reason: "User not authenticated")
        }
        return userId
    }
    
    private func requireNetwork() throws {
        guard NetworkMonitor.shared.isConnected else {
            throw KiroError.networkError(underlying: NSError(
                domain: "SyncService",
                code: 3001,
                userInfo: [NSLocalizedDescriptionKey: "No network connection"]
            ))
        }
    }
    
    // MARK: - Initial Sync
    
    /// Performs initial sync on login - fetches all user anime lists from AniList
    private func performSyncAll() async throws {
        try requireNetwork()
        
        let userId = try await resolveUserId()
        
        // Fetch all anime lists from AniList
        let query = FetchUserAnimeListQuery(userId: userId, status: nil)
        let response: MediaListCollectionResponse = try await apiClient.execute(query: query)
        
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let pendingDeletes = self.pendingDeleteMediaIds(context: context)
            
            for list in response.MediaListCollection.lists {
                for entry in list.entries where !pendingDeletes.contains(entry.media.id) {
                    try self.processRemoteEntry(entry, context: context)
                }
            }
            
            try context.save()
        }
    }
    
    // MARK: - Incremental Sync
    
    /// Performs incremental sync - fetches updates from AniList and merges with local changes
    private func performSyncUserLists() async throws {
        try requireNetwork()
        
        let userId = try await resolveUserId()
        
        // Fetch all anime lists from AniList
        let query = FetchUserAnimeListQuery(userId: userId, status: nil)
        let response: MediaListCollectionResponse = try await apiClient.execute(query: query)
        
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            // Get all local user anime
            let localUserAnime = self.coreDataStack.fetchAllUserAnime(context: context)
            let localAnimeIds = Set(localUserAnime.map { Int($0.animeId) })
            
            // Entries deleted locally but not yet deleted on AniList must not be re-added
            let pendingDeletes = self.pendingDeleteMediaIds(context: context)
            
            // Track remote anime IDs
            var remoteAnimeIds = Set<Int>()
            
            // Process remote entries
            for list in response.MediaListCollection.lists {
                for entry in list.entries {
                    remoteAnimeIds.insert(entry.media.id)
                    guard !pendingDeletes.contains(entry.media.id) else { continue }
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
    
    /// Snapshot of a queue item, read inside the context's queue.
    private struct QueueItemSnapshot {
        /// Changes every time the item is updated; used to detect edits made while a request was in flight.
        let version: UUID?
        let operation: String
        let mediaId: Int
        let change: QueuedChange
    }
    
    /// Processes queued operations when connection is restored.
    ///
    /// - Transient failures (offline, timeout, rate limit, server error) stop
    ///   processing and leave the queue untouched for the next attempt.
    /// - Permanent failures (e.g. AniList rejects the request) count toward
    ///   `maxQueueRetries`. When an item is dropped, the entry's `needsSync`
    ///   flag is cleared so the next sync restores AniList's values instead of
    ///   leaving the entry stuck.
    /// - An expired or revoked token is rethrown so the caller can sign out.
    private func performProcessSyncQueue() async throws {
        // Silently return if offline
        guard NetworkMonitor.shared.isConnected else { return }
        
        let context = coreDataStack.newBackgroundContext()
        
        let snapshots: [QueueItemSnapshot] = await context.perform {
            self.coreDataStack.fetchSyncQueue(context: context).map { item in
                QueueItemSnapshot(
                    version: item.id,
                    operation: item.operation ?? "",
                    mediaId: Int(item.entityId),
                    change: QueuedChange(payload: item.payload)
                )
            }
        }
        
        for snapshot in snapshots {
            do {
                let remoteEntryId = try await sendQueuedChange(snapshot)
                
                await context.perform {
                    self.finishQueueItem(snapshot, remoteEntryId: remoteEntryId, context: context)
                }
            } catch {
                if let kiroError = error as? KiroError, AuthenticationService.isInvalidTokenError(kiroError) {
                    throw error
                }
                if Self.isTransient(error) {
                    // Try again later; later items would most likely fail the same way
                    return
                }
                
                await context.perform {
                    self.recordPermanentFailure(snapshot, error: error, context: context)
                }
            }
        }
    }
    
    /// Sends one queued change to AniList.
    /// - Returns: The remote list entry ID for saves, nil for deletes.
    private func sendQueuedChange(_ snapshot: QueueItemSnapshot) async throws -> Int? {
        if snapshot.operation == QueuedChange.deleteOperation {
            try await deleteRemoteEntry(mediaId: snapshot.mediaId)
            return nil
        }
        
        let change = snapshot.change
        guard change.status != nil || change.progress != nil || change.score != nil else {
            throw KiroError.decodingError(underlying: NSError(
                domain: "SyncService",
                code: 2001,
                userInfo: [NSLocalizedDescriptionKey: "Queue item has no changes to send"]
            ))
        }
        
        let mutation = SaveMediaListEntryMutation(
            mediaId: snapshot.mediaId,
            status: change.status,
            progress: change.progress,
            score: change.score
        )
        let response: SaveMediaListEntryResponse = try await apiClient.execute(mutation: mutation)
        return response.SaveMediaListEntry.id
    }
    
    /// Deletes the user's AniList entry for a media item.
    ///
    /// The entry ID is looked up from AniList because entries added offline
    /// only have a local placeholder ID. If AniList has no entry, there is
    /// nothing to delete and the operation succeeds.
    private func deleteRemoteEntry(mediaId: Int) async throws {
        // If the profile can't be loaded, the error is transient and the delete is retried later
        let userId = try await resolveUserId()
        
        let entryId: Int
        do {
            let response: MediaListEntryIdResponse = try await apiClient.execute(
                query: FetchMediaListEntryIdQuery(userId: userId, mediaId: mediaId)
            )
            guard let id = response.MediaList?.id else { return }
            entryId = id
        } catch KiroError.apiError(_, let statusCode) where statusCode == 404 {
            return
        }
        
        let mutation = DeleteMediaListEntryMutation(id: entryId)
        let _: DeleteMediaListEntryResponse = try await apiClient.execute(mutation: mutation)
    }
    
    /// Removes a processed queue item, unless it was updated while the request
    /// was in flight (in which case the newer change is sent on the next pass).
    private func finishQueueItem(_ snapshot: QueueItemSnapshot, remoteEntryId: Int?, context: NSManagedObjectContext) {
        let currentItem = snapshot.version.flatMap { coreDataStack.fetchSyncQueueItem(byId: $0, context: context) }
        let itemUnchanged = currentItem != nil
        
        if let currentItem = currentItem {
            context.delete(currentItem)
        }
        
        if let userAnime = coreDataStack.fetchUserAnime(byAnimeId: Int64(snapshot.mediaId), context: context) {
            if let remoteEntryId = remoteEntryId {
                userAnime.id = Int64(remoteEntryId)
            }
            if itemUnchanged {
                userAnime.needsSync = false
            }
        }
        
        try? context.save()
    }
    
    private func recordPermanentFailure(_ snapshot: QueueItemSnapshot, error: Error, context: NSManagedObjectContext) {
        // Look the item up by version in the store: if queueOperation() updated it
        // meanwhile, the version changed and the new version gets its own retries.
        guard let version = snapshot.version,
              let item = coreDataStack.fetchSyncQueueItem(byId: version, context: context) else {
            return
        }
        
        item.retryCount += 1
        
        if item.retryCount >= Self.maxQueueRetries {
            print("SyncService: dropping \(snapshot.operation) for media \(snapshot.mediaId) after \(item.retryCount) failures: \(error.localizedDescription)")
            context.delete(item)
            
            // Let the next sync restore AniList's values for this entry
            if let userAnime = coreDataStack.fetchUserAnime(byAnimeId: Int64(snapshot.mediaId), context: context) {
                userAnime.needsSync = false
            }
        }
        
        try? context.save()
    }
    
    private static let maxQueueRetries = 5
    
    /// Errors that will likely succeed if retried later without any change.
    private static func isTransient(_ error: Error) -> Bool {
        guard let kiroError = error as? KiroError else {
            return (error as NSError).domain == NSURLErrorDomain
        }
        
        switch kiroError {
        case .networkError, .noInternetConnection, .timeout, .serverUnavailable, .rateLimitExceeded, .authenticationFailed:
            return true
        case .apiError(_, let statusCode):
            guard let code = statusCode else { return false }
            return code == 429 || code >= 500
        default:
            return false
        }
    }
    
    /// Media IDs with a queued delete that hasn't reached AniList yet.
    private func pendingDeleteMediaIds(context: NSManagedObjectContext) -> Set<Int> {
        Set(coreDataStack.fetchSyncQueue(context: context)
            .filter { $0.operation == QueuedChange.deleteOperation }
            .map { Int($0.entityId) })
    }
    
    // MARK: - Queue Operation
    
    /// Queues an operation for later sync.
    ///
    /// There is at most one queue item per media ID. New edits are merged into
    /// the existing item (e.g. an offline progress change followed by a score
    /// change sends both), and a delete replaces any pending edits.
    func queueOperation(_ operation: SyncOperation) {
        let context = coreDataStack.viewContext
        
        let mediaId: Int
        switch operation {
        case .updateProgress(let id, _, _), .updateStatus(let id, _), .updateScore(let id, _):
            mediaId = id
        case .deleteEntry(_, let id):
            mediaId = id
        }
        
        let existingItem = coreDataStack.fetchSyncQueue(context: context)
            .first(where: { $0.entityId == Int64(mediaId) })
        
        let queueItem = existingItem ?? SyncQueueEntity(context: context)
        let existingChange: QueuedChange
        if let existingItem = existingItem, existingItem.operation != QueuedChange.deleteOperation {
            existingChange = QueuedChange(payload: existingItem.payload)
        } else {
            existingChange = QueuedChange()
        }
        
        let change: QueuedChange
        let operationName: String
        
        switch operation {
        case .updateProgress(_, let progress, let status):
            var merged = existingChange
            merged.progress = progress
            if let status = status { merged.status = status }
            change = merged
            operationName = merged.operationName
            
        case .updateStatus(_, let status):
            var merged = existingChange
            merged.status = status
            change = merged
            operationName = merged.operationName
            
        case .updateScore(_, let score):
            var merged = existingChange
            merged.score = score
            change = merged
            operationName = merged.operationName
            
        case .deleteEntry(let entryId, _):
            change = QueuedChange(entryId: entryId)
            operationName = QueuedChange.deleteOperation
        }
        
        // A new UUID marks this as a new version of the item, so an in-flight
        // request for the previous version doesn't delete it on completion.
        queueItem.id = UUID()
        queueItem.createdAt = Date()
        queueItem.retryCount = 0
        queueItem.entityType = "UserAnime"
        queueItem.entityId = Int64(mediaId)
        queueItem.operation = operationName
        queueItem.payload = change.encodedPayload(mediaId: mediaId)
        
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
                existingUserAnime.id = Int64(entry.id)
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
    
    private func fetchOrCreateAnimeEntity(from anime: Anime, context: NSManagedObjectContext) throws -> AnimeEntity {
        // Try to fetch existing anime
        if let existing = coreDataStack.fetchAnime(byId: Int64(anime.id), context: context) {
            // Update existing anime data
            existing.titleRomaji = anime.title.romaji
            existing.titleEnglish = anime.title.english
            existing.titleNative = anime.title.native
            existing.coverImageLarge = anime.coverImage.large
            existing.coverImageMedium = anime.coverImage.medium
            existing.bannerImage = anime.bannerImage
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
        animeEntity.bannerImage = anime.bannerImage
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
            bannerImage: media.bannerImage,
            episodes: media.episodes,
            format: format,
            genres: media.genres,
            synopsis: media.description,
            siteUrl: media.siteUrl
        )
    }
}

// MARK: - Queued Change

/// The fields a queue item will send to AniList. Stored as base64-encoded
/// JSON in `SyncQueueEntity.payload` (same format as earlier versions, so
/// items queued before an upgrade are still processed).
private struct QueuedChange {
    static let deleteOperation = "deleteEntry"
    
    var status: String?
    var progress: Int?
    var score: Double?
    var entryId: Int?
    
    init(status: String? = nil, progress: Int? = nil, score: Double? = nil, entryId: Int? = nil) {
        self.status = status
        self.progress = progress
        self.score = score
        self.entryId = entryId
    }
    
    init(payload: String?) {
        guard let payload = payload,
              let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            self.init()
            return
        }
        
        self.init(
            status: json["status"] as? String,
            progress: (json["progress"] as? NSNumber)?.intValue,
            score: (json["score"] as? NSNumber)?.doubleValue,
            entryId: (json["entryId"] as? NSNumber)?.intValue
        )
    }
    
    /// Operation name stored on the queue item. Single-field changes keep the
    /// original names; combined changes are stored as "saveEntry".
    var operationName: String {
        switch (status != nil, progress != nil, score != nil) {
        case (_, true, false): return "updateProgress"
        case (true, false, false): return "updateStatus"
        case (false, false, true): return "updateScore"
        default: return "saveEntry"
        }
    }
    
    func encodedPayload(mediaId: Int) -> String? {
        var json: [String: Any] = ["mediaId": mediaId]
        if let status = status { json["status"] = status }
        if let progress = progress { json["progress"] = progress }
        if let score = score { json["score"] = score }
        if let entryId = entryId { json["entryId"] = entryId }
        return try? JSONSerialization.data(withJSONObject: json).base64EncodedString()
    }
}
