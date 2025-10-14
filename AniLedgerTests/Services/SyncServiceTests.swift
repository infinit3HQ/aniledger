//
//  SyncServiceTests.swift
//  AniLedgerTests
//
//  Created by Kiro on 10/13/2025.
//

import XCTest
import CoreData
@testable import AniLedger

final class SyncServiceTests: XCTestCase {
    var syncService: SyncService!
    var mockAPIClient: MockAniListAPIClient!
    var coreDataStack: CoreDataStack!
    var animeService: AnimeService!
    var mockUserId: Int?
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory Core Data stack for testing
        coreDataStack = CoreDataStack(inMemory: true)
        animeService = AnimeService(coreDataStack: coreDataStack)
        mockAPIClient = MockAniListAPIClient()
        mockUserId = 12345
        
        syncService = SyncService(
            apiClient: mockAPIClient,
            coreDataStack: coreDataStack,
            animeService: animeService,
            userIdProvider: { [weak self] in self?.mockUserId }
        )
    }
    
    override func tearDown() {
        // Clean up
        try? coreDataStack.clearAllData()
        syncService = nil
        mockAPIClient = nil
        animeService = nil
        coreDataStack = nil
        mockUserId = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestMediaResponse(id: Int, title: String, status: String = "CURRENT", progress: Int = 0) -> MediaListEntry {
        return MediaListEntry(
            id: id,
            status: status,
            progress: progress,
            score: nil,
            media: MediaResponse(
                id: id,
                title: TitleResponse(romaji: title, english: "\(title) EN", native: "\(title) JP"),
                coverImage: CoverImageResponse(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
                episodes: 12,
                format: "TV",
                genres: ["Action", "Adventure"],
                description: "Test synopsis",
                siteUrl: "https://anilist.co/anime/\(id)"
            )
        )
    }
    
    private func createTestAnime(id: Int = 1, title: String = "Test Anime") -> Anime {
        return Anime(
            id: id,
            title: AnimeTitle(romaji: title, english: "\(title) EN", native: "\(title) JP"),
            coverImage: CoverImage(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            episodes: 12,
            format: .tv,
            genres: ["Action", "Adventure"],
            synopsis: "Test synopsis",
            siteUrl: "https://anilist.co/anime/\(id)"
        )
    }
    
    // MARK: - Initial Sync Tests
    
    func testSyncAllFetchesUserAnimeList() async throws {
        // Given
        let entry1 = createTestMediaResponse(id: 1, title: "Anime 1", status: "CURRENT", progress: 5)
        let entry2 = createTestMediaResponse(id: 2, title: "Anime 2", status: "COMPLETED", progress: 12)
        
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [entry1, entry2])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncAll()
        
        // Then
        XCTAssertEqual(mockAPIClient.executeQueryCallCount, 1)
        
        let allUserAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allUserAnime.count, 2)
        
        let anime1 = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertNotNil(anime1)
        XCTAssertEqual(anime1?.status, .watching)
        XCTAssertEqual(anime1?.progress, 5)
        XCTAssertFalse(anime1?.needsSync ?? true)
        
        let anime2 = try animeService.getUserAnime(byAnimeId: 2)
        XCTAssertNotNil(anime2)
        XCTAssertEqual(anime2?.status, .completed)
        XCTAssertEqual(anime2?.progress, 12)
    }
    
    func testSyncAllWithEmptyList() async throws {
        // Given
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(lists: [])
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncAll()
        
        // Then
        XCTAssertEqual(mockAPIClient.executeQueryCallCount, 1)
        
        let allUserAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allUserAnime.count, 0)
    }
    
    func testSyncAllWithoutAuthenticationThrowsError() async throws {
        // Given
        mockUserId = nil
        
        // When/Then
        do {
            try await syncService.syncAll()
            XCTFail("Expected authentication error")
        } catch let error as KiroError {
            if case .authenticationFailed = error {
                // Expected error
            } else {
                XCTFail("Expected authenticationFailed error")
            }
        }
    }
    
    func testSyncAllHandlesAPIError() async throws {
        // Given
        mockAPIClient.shouldThrowError = KiroError.apiError(message: "API Error", statusCode: 500)
        
        // When/Then
        do {
            try await syncService.syncAll()
            XCTFail("Expected API error")
        } catch let error as KiroError {
            if case .apiError = error {
                // Expected error
            } else {
                XCTFail("Expected apiError")
            }
        }
    }
    
    // MARK: - Incremental Sync Tests
    
    func testSyncUserListsMergesRemoteChanges() async throws {
        // Given - Add local anime
        let anime = createTestAnime(id: 1, title: "Local Anime")
        _ = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 3)
        
        // Given - Remote has updated progress
        let remoteEntry = createTestMediaResponse(id: 1, title: "Local Anime", status: "CURRENT", progress: 7)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then
        let updatedAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertEqual(updatedAnime?.progress, 7) // Remote wins
        XCTAssertFalse(updatedAnime?.needsSync ?? true)
    }
    
    func testSyncUserListsPreservesLocalChangesWithNeedsSync() async throws {
        // Given - Add local anime with pending changes
        let anime = createTestAnime(id: 1, title: "Local Anime")
        var userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 3)
        userAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        
        XCTAssertTrue(userAnime.needsSync)
        
        // Given - Remote has different progress
        let remoteEntry = createTestMediaResponse(id: 1, title: "Local Anime", status: "CURRENT", progress: 2)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then - Local changes should be preserved
        let updatedAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertEqual(updatedAnime?.progress, 5) // Local wins because needsSync is true
        XCTAssertTrue(updatedAnime?.needsSync ?? false)
    }
    
    func testSyncUserListsAddsNewRemoteAnime() async throws {
        // Given - Remote has new anime
        let remoteEntry = createTestMediaResponse(id: 1, title: "New Anime", status: "CURRENT", progress: 5)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then
        let newAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertNotNil(newAnime)
        XCTAssertEqual(newAnime?.progress, 5)
        XCTAssertEqual(newAnime?.status, .watching)
        XCTAssertFalse(newAnime?.needsSync ?? true)
    }
    
    func testSyncUserListsRemovesDeletedRemoteAnime() async throws {
        // Given - Add local anime
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        
        // Given - Remote only has anime 1
        let remoteEntry = createTestMediaResponse(id: 1, title: "Anime 1", status: "CURRENT", progress: 0)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then - Anime 2 should be removed
        let allAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allAnime.count, 1)
        XCTAssertEqual(allAnime[0].anime.id, 1)
        
        let deletedAnime = try animeService.getUserAnime(byAnimeId: 2)
        XCTAssertNil(deletedAnime)
    }
    
    func testSyncUserListsDoesNotRemoveLocalChangesWithNeedsSync() async throws {
        // Given - Add local anime with pending changes
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        let userAnime2 = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.updateAnimeProgress(userAnime2.id, progress: 5)
        
        // Given - Remote only has anime 1
        let remoteEntry = createTestMediaResponse(id: 1, title: "Anime 1", status: "CURRENT", progress: 0)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then - Anime 2 should NOT be removed because it has pending changes
        let allAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allAnime.count, 2)
        
        let anime2 = try animeService.getUserAnime(byAnimeId: 2)
        XCTAssertNotNil(anime2)
        XCTAssertTrue(anime2?.needsSync ?? false)
    }
    
    func testSyncUserListsHandlesMultipleLists() async throws {
        // Given
        let entry1 = createTestMediaResponse(id: 1, title: "Watching", status: "CURRENT", progress: 5)
        let entry2 = createTestMediaResponse(id: 2, title: "Completed", status: "COMPLETED", progress: 12)
        let entry3 = createTestMediaResponse(id: 3, title: "Planning", status: "PLANNING", progress: 0)
        
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [
                    MediaList(entries: [entry1]),
                    MediaList(entries: [entry2, entry3])
                ]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then
        let allAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allAnime.count, 3)
        
        let watching = try animeService.fetchAnimeByStatus(.watching)
        let completed = try animeService.fetchAnimeByStatus(.completed)
        let planning = try animeService.fetchAnimeByStatus(.planToWatch)
        
        XCTAssertEqual(watching.count, 1)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(planning.count, 1)
    }
    
    // MARK: - Sync Queue Processing Tests
    
    func testProcessSyncQueueExecutesPendingOperations() async throws {
        // Given - Queue an update progress operation
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: "CURRENT"))
        
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 1)
        
        // Given - Mock API response
        let mutationResponse = SaveMediaListEntryResponse(
            SaveMediaListEntry: createTestMediaResponse(id: 1, title: "Test", status: "CURRENT", progress: 5)
        )
        mockAPIClient.mutationResult = mutationResponse
        
        // When
        try await syncService.processSyncQueue()
        
        // Then
        XCTAssertEqual(mockAPIClient.executeMutationCallCount, 1)
        
        let remainingQueueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(remainingQueueItems.count, 0)
    }
    
    func testProcessSyncQueueHandlesMultipleOperations() async throws {
        // Given - Queue multiple operations
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: nil))
        syncService.queueOperation(.updateStatus(mediaId: 2, status: "COMPLETED"))
        syncService.queueOperation(.updateProgress(mediaId: 3, progress: 10, status: "CURRENT"))
        
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 3)
        
        // Given - Mock API response
        let mutationResponse = SaveMediaListEntryResponse(
            SaveMediaListEntry: createTestMediaResponse(id: 1, title: "Test", status: "CURRENT", progress: 5)
        )
        mockAPIClient.mutationResult = mutationResponse
        
        // When
        try await syncService.processSyncQueue()
        
        // Then
        XCTAssertEqual(mockAPIClient.executeMutationCallCount, 3)
        
        let remainingQueueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(remainingQueueItems.count, 0)
    }
    
    func testProcessSyncQueueIncrementsRetryCountOnFailure() async throws {
        // Given - Queue an operation
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: nil))
        
        // Given - Mock API error
        mockAPIClient.shouldThrowError = KiroError.networkError(underlying: NSError(domain: "Test", code: 1))
        
        // When
        try await syncService.processSyncQueue()
        
        // Then
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 1)
        XCTAssertEqual(queueItems[0].retryCount, 1)
    }
    
    func testProcessSyncQueueRemovesItemAfterMaxRetries() async throws {
        // Given - Queue an operation and set retry count to 4
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: nil))
        
        let queueItems = coreDataStack.fetchSyncQueue()
        queueItems[0].retryCount = 4
        try coreDataStack.saveContext()
        
        // Given - Mock API error
        mockAPIClient.shouldThrowError = KiroError.networkError(underlying: NSError(domain: "Test", code: 1))
        
        // When
        try await syncService.processSyncQueue()
        
        // Then - Item should be removed after 5th retry
        let remainingQueueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(remainingQueueItems.count, 0)
    }
    
    func testProcessSyncQueueContinuesAfterFailure() async throws {
        // Given - Queue multiple operations
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: nil))
        syncService.queueOperation(.updateProgress(mediaId: 2, progress: 10, status: nil))
        
        // Given - First call fails, second succeeds
        var callCount = 0
        mockAPIClient.shouldThrowError = KiroError.networkError(underlying: NSError(domain: "Test", code: 1))
        
        // When
        try await syncService.processSyncQueue()
        
        // Then - Both operations should be attempted
        XCTAssertEqual(mockAPIClient.executeMutationCallCount, 2)
        
        // Both items should still be in queue due to failure
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 2)
    }
    
    func testProcessSyncQueueUpdatesNeedsSyncFlag() async throws {
        // Given - Add anime with needsSync flag
        let anime = createTestAnime(id: 1, title: "Test Anime")
        var userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        userAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        
        XCTAssertTrue(userAnime.needsSync)
        
        // Given - Queue operation
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: nil))
        
        // Given - Mock API response
        let mutationResponse = SaveMediaListEntryResponse(
            SaveMediaListEntry: createTestMediaResponse(id: 1, title: "Test", status: "CURRENT", progress: 5)
        )
        mockAPIClient.mutationResult = mutationResponse
        
        // When
        try await syncService.processSyncQueue()
        
        // Then
        let updatedAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertFalse(updatedAnime?.needsSync ?? true)
    }
    
    // MARK: - Queue Operation Tests
    
    func testQueueOperationUpdateProgress() {
        // When
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: "CURRENT"))
        
        // Then
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 1)
        
        let item = queueItems[0]
        XCTAssertEqual(item.operation, "updateProgress")
        XCTAssertEqual(item.entityType, "UserAnime")
        XCTAssertEqual(item.entityId, 1)
        XCTAssertEqual(item.retryCount, 0)
        XCTAssertNotNil(item.payload)
    }
    
    func testQueueOperationUpdateStatus() {
        // When
        syncService.queueOperation(.updateStatus(mediaId: 2, status: "COMPLETED"))
        
        // Then
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 1)
        
        let item = queueItems[0]
        XCTAssertEqual(item.operation, "updateStatus")
        XCTAssertEqual(item.entityType, "UserAnime")
        XCTAssertEqual(item.entityId, 2)
    }
    
    func testQueueOperationDeleteEntry() {
        // When
        syncService.queueOperation(.deleteEntry(mediaId: 3))
        
        // Then
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 1)
        
        let item = queueItems[0]
        XCTAssertEqual(item.operation, "deleteEntry")
        XCTAssertEqual(item.entityType, "UserAnime")
        XCTAssertEqual(item.entityId, 3)
    }
    
    func testQueueOperationMultipleOperations() {
        // When
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: nil))
        syncService.queueOperation(.updateStatus(mediaId: 2, status: "COMPLETED"))
        syncService.queueOperation(.deleteEntry(mediaId: 3))
        
        // Then
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 3)
    }
    
    func testQueueOperationPreservesOrder() {
        // When
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 1, status: nil))
        Thread.sleep(forTimeInterval: 0.01)
        syncService.queueOperation(.updateProgress(mediaId: 2, progress: 2, status: nil))
        Thread.sleep(forTimeInterval: 0.01)
        syncService.queueOperation(.updateProgress(mediaId: 3, progress: 3, status: nil))
        
        // Then
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 3)
        
        // Items should be ordered by creation date
        XCTAssertEqual(queueItems[0].entityId, 1)
        XCTAssertEqual(queueItems[1].entityId, 2)
        XCTAssertEqual(queueItems[2].entityId, 3)
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testConflictResolutionRemoteWins() async throws {
        // Given - Local anime with no pending changes
        let anime = createTestAnime(id: 1, title: "Test Anime")
        var userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 3)
        
        // Clear needsSync flag to simulate synced state
        let context = coreDataStack.viewContext
        if let entity = coreDataStack.fetchUserAnime(byAnimeId: Int64(anime.id), context: context) {
            entity.needsSync = false
            try coreDataStack.saveContext()
        }
        
        // Given - Remote has different progress
        let remoteEntry = createTestMediaResponse(id: 1, title: "Test Anime", status: "CURRENT", progress: 7)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then - Remote should win
        let updatedAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertEqual(updatedAnime?.progress, 7)
    }
    
    func testConflictResolutionLocalWinsWithPendingChanges() async throws {
        // Given - Local anime with pending changes
        let anime = createTestAnime(id: 1, title: "Test Anime")
        var userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 3)
        userAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        
        XCTAssertTrue(userAnime.needsSync)
        
        // Given - Remote has different progress
        let remoteEntry = createTestMediaResponse(id: 1, title: "Test Anime", status: "CURRENT", progress: 2)
        let response = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [remoteEntry])]
            )
        )
        
        mockAPIClient.queryResult = response
        
        // When
        try await syncService.syncUserLists()
        
        // Then - Local should win
        let updatedAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertEqual(updatedAnime?.progress, 5)
        XCTAssertTrue(updatedAnime?.needsSync ?? false)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteOfflineSyncWorkflow() async throws {
        // Given - Add anime locally while "offline"
        let anime = createTestAnime(id: 1, title: "Offline Anime")
        var userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 0)
        
        // Update progress while offline
        userAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        XCTAssertTrue(userAnime.needsSync)
        
        // Queue the operation
        syncService.queueOperation(.updateProgress(mediaId: 1, progress: 5, status: "CURRENT"))
        
        // Given - Mock API response for sync queue processing
        let mutationResponse = SaveMediaListEntryResponse(
            SaveMediaListEntry: createTestMediaResponse(id: 1, title: "Offline Anime", status: "CURRENT", progress: 5)
        )
        mockAPIClient.mutationResult = mutationResponse
        
        // When - Process sync queue (coming back online)
        try await syncService.processSyncQueue()
        
        // Then
        XCTAssertEqual(mockAPIClient.executeMutationCallCount, 1)
        
        let queueItems = coreDataStack.fetchSyncQueue()
        XCTAssertEqual(queueItems.count, 0)
        
        let updatedAnime = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertFalse(updatedAnime?.needsSync ?? true)
    }
    
    func testInitialSyncFollowedByIncrementalSync() async throws {
        // Given - Initial sync
        let entry1 = createTestMediaResponse(id: 1, title: "Anime 1", status: "CURRENT", progress: 5)
        let entry2 = createTestMediaResponse(id: 2, title: "Anime 2", status: "COMPLETED", progress: 12)
        
        let initialResponse = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [entry1, entry2])]
            )
        )
        
        mockAPIClient.queryResult = initialResponse
        
        // When - Initial sync
        try await syncService.syncAll()
        
        // Then
        var allAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allAnime.count, 2)
        
        // Given - Update local anime
        if let userAnime = try animeService.getUserAnime(byAnimeId: 1) {
            _ = try animeService.updateAnimeProgress(userAnime.id, progress: 7)
        }
        
        // Given - Remote has new anime and updated anime 2
        let entry2Updated = createTestMediaResponse(id: 2, title: "Anime 2", status: "COMPLETED", progress: 12)
        let entry3 = createTestMediaResponse(id: 3, title: "Anime 3", status: "PLANNING", progress: 0)
        
        let incrementalResponse = MediaListCollectionResponse(
            MediaListCollection: MediaListCollection(
                lists: [MediaList(entries: [entry1, entry2Updated, entry3])]
            )
        )
        
        mockAPIClient.queryResult = incrementalResponse
        mockAPIClient.executeQueryCallCount = 0
        
        // When - Incremental sync
        try await syncService.syncUserLists()
        
        // Then
        allAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allAnime.count, 3)
        
        // Anime 1 should keep local changes
        let anime1 = try animeService.getUserAnime(byAnimeId: 1)
        XCTAssertEqual(anime1?.progress, 7)
        XCTAssertTrue(anime1?.needsSync ?? false)
        
        // Anime 3 should be added
        let anime3 = try animeService.getUserAnime(byAnimeId: 3)
        XCTAssertNotNil(anime3)
        XCTAssertEqual(anime3?.status, .planToWatch)
    }
}
