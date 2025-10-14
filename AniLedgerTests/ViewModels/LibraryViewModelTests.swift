//
//  LibraryViewModelTests.swift
//  AniLedgerTests
//
//  Unit tests for LibraryViewModel
//

import XCTest
import CoreData
@testable import AniLedger

@MainActor
final class LibraryViewModelTests: XCTestCase {
    var viewModel: LibraryViewModel!
    var mockAnimeService: MockAnimeService!
    var mockSyncService: MockSyncService!
    
    override func setUp() {
        super.setUp()
        
        mockAnimeService = MockAnimeService()
        mockSyncService = MockSyncService()
        viewModel = LibraryViewModel(
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockAnimeService = nil
        mockSyncService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
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
    
    private func createTestUserAnime(id: Int, anime: Anime, status: AnimeStatus, progress: Int = 0, sortOrder: Int = 0) -> UserAnime {
        return UserAnime(
            id: id,
            anime: anime,
            status: status,
            progress: progress,
            score: nil,
            sortOrder: sortOrder,
            needsSync: false,
            lastModified: Date()
        )
    }
    
    // MARK: - Load Lists Tests
    
    func testLoadListsPopulatesCorrectLists() async throws {
        // Given
        let watchingAnime1 = createTestUserAnime(id: 1, anime: createTestAnime(id: 1, title: "Watching 1"), status: .watching)
        let watchingAnime2 = createTestUserAnime(id: 2, anime: createTestAnime(id: 2, title: "Watching 2"), status: .watching)
        let completedAnime = createTestUserAnime(id: 3, anime: createTestAnime(id: 3, title: "Completed 1"), status: .completed)
        let planToWatchAnime = createTestUserAnime(id: 4, anime: createTestAnime(id: 4, title: "Plan to Watch 1"), status: .planToWatch)
        let onHoldAnime = createTestUserAnime(id: 5, anime: createTestAnime(id: 5, title: "On Hold 1"), status: .onHold)
        let droppedAnime = createTestUserAnime(id: 6, anime: createTestAnime(id: 6, title: "Dropped 1"), status: .dropped)
        
        mockAnimeService.animeByStatus = [
            .watching: [watchingAnime1, watchingAnime2],
            .completed: [completedAnime],
            .planToWatch: [planToWatchAnime],
            .onHold: [onHoldAnime],
            .dropped: [droppedAnime]
        ]
        
        // When
        viewModel.loadLists()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.watchingList.count, 2)
        XCTAssertEqual(viewModel.completedList.count, 1)
        XCTAssertEqual(viewModel.planToWatchList.count, 1)
        XCTAssertEqual(viewModel.onHoldList.count, 1)
        XCTAssertEqual(viewModel.droppedList.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadListsWithEmptyLists() async throws {
        // Given
        mockAnimeService.animeByStatus = [
            .watching: [],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.loadLists()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.watchingList.count, 0)
        XCTAssertEqual(viewModel.completedList.count, 0)
        XCTAssertEqual(viewModel.planToWatchList.count, 0)
        XCTAssertEqual(viewModel.onHoldList.count, 0)
        XCTAssertEqual(viewModel.droppedList.count, 0)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadListsSetsLoadingState() {
        // Given
        mockAnimeService.animeByStatus = [
            .watching: [],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        XCTAssertFalse(viewModel.isLoading)
        viewModel.loadLists()
        
        // Then - loading should be set immediately
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testLoadListsHandlesError() async throws {
        // Given
        mockAnimeService.shouldThrowError = KiroError.coreDataError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        ))
        
        // When
        viewModel.loadLists()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        if case .coreDataError = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected coreDataError")
        }
    }
    
    // MARK: - Move Anime Tests
    
    func testMoveAnimeUpdatesStatusAndTriggersSync() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        let userAnime = createTestUserAnime(id: 1, anime: anime, status: .watching, progress: 5)
        
        let movedAnime = createTestUserAnime(id: 1, anime: anime, status: .completed, progress: 5)
        mockAnimeService.moveAnimeBetweenListsResult = movedAnime
        
        mockAnimeService.animeByStatus = [
            .watching: [],
            .completed: [movedAnime],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.moveAnime(userAnime, to: .completed)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockAnimeService.moveAnimeBetweenListsCallCount, 1)
        XCTAssertEqual(mockAnimeService.lastMovedAnimeId, 1)
        XCTAssertEqual(mockAnimeService.lastMovedToStatus, .completed)
        
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
        XCTAssertEqual(mockSyncService.processSyncQueueCallCount, 1)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testMoveAnimeReloadsLists() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        let userAnime = createTestUserAnime(id: 1, anime: anime, status: .watching)
        
        let movedAnime = createTestUserAnime(id: 1, anime: anime, status: .completed)
        mockAnimeService.moveAnimeBetweenListsResult = movedAnime
        
        mockAnimeService.animeByStatus = [
            .watching: [],
            .completed: [movedAnime],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.moveAnime(userAnime, to: .completed)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.completedList.count, 1)
        XCTAssertEqual(viewModel.watchingList.count, 0)
    }
    
    func testMoveAnimeHandlesError() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        let userAnime = createTestUserAnime(id: 1, anime: anime, status: .watching)
        
        mockAnimeService.shouldThrowError = KiroError.coreDataError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Move failed"]
        ))
        
        // When
        viewModel.moveAnime(userAnime, to: .completed)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Reorder Anime Tests
    
    func testReorderAnimeUpdatesSortOrder() async throws {
        // Given
        let anime1 = createTestUserAnime(id: 1, anime: createTestAnime(id: 1, title: "First"), status: .watching, sortOrder: 0)
        let anime2 = createTestUserAnime(id: 2, anime: createTestAnime(id: 2, title: "Second"), status: .watching, sortOrder: 1)
        let anime3 = createTestUserAnime(id: 3, anime: createTestAnime(id: 3, title: "Third"), status: .watching, sortOrder: 2)
        
        // After reorder: anime3, anime1, anime2
        let reorderedAnime1 = createTestUserAnime(id: 1, anime: createTestAnime(id: 1, title: "First"), status: .watching, sortOrder: 1)
        let reorderedAnime2 = createTestUserAnime(id: 2, anime: createTestAnime(id: 2, title: "Second"), status: .watching, sortOrder: 2)
        let reorderedAnime3 = createTestUserAnime(id: 3, anime: createTestAnime(id: 3, title: "Third"), status: .watching, sortOrder: 0)
        
        mockAnimeService.animeByStatus = [
            .watching: [reorderedAnime3, reorderedAnime1, reorderedAnime2],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.reorderAnime(in: .watching, from: 2, to: 0)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockAnimeService.reorderAnimeCallCount, 1)
        XCTAssertEqual(mockAnimeService.lastReorderStatus, .watching)
        XCTAssertEqual(mockAnimeService.lastReorderSourceIndex, 2)
        XCTAssertEqual(mockAnimeService.lastReorderDestinationIndex, 0)
        
        XCTAssertEqual(viewModel.watchingList.count, 3)
        XCTAssertEqual(viewModel.watchingList[0].sortOrder, 0)
        XCTAssertEqual(viewModel.watchingList[1].sortOrder, 1)
        XCTAssertEqual(viewModel.watchingList[2].sortOrder, 2)
        
        XCTAssertNil(viewModel.error)
    }
    
    func testReorderAnimeOnlyUpdatesSpecificList() async throws {
        // Given
        let watchingAnime = createTestUserAnime(id: 1, anime: createTestAnime(id: 1, title: "Watching"), status: .watching)
        let completedAnime = createTestUserAnime(id: 2, anime: createTestAnime(id: 2, title: "Completed"), status: .completed)
        
        mockAnimeService.animeByStatus = [
            .watching: [watchingAnime],
            .completed: [completedAnime],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // Load initial lists
        viewModel.loadLists()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let initialCompletedCount = viewModel.completedList.count
        
        // When - reorder watching list
        viewModel.reorderAnime(in: .watching, from: 0, to: 0)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - completed list should remain unchanged
        XCTAssertEqual(viewModel.completedList.count, initialCompletedCount)
    }
    
    func testReorderAnimeHandlesError() async throws {
        // Given
        mockAnimeService.shouldThrowError = KiroError.coreDataError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Reorder failed"]
        ))
        
        // When
        viewModel.reorderAnime(in: .watching, from: 0, to: 1)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Delete Anime Tests
    
    func testDeleteAnimeRemovesFromLibrary() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        let userAnime = createTestUserAnime(id: 1, anime: anime, status: .watching)
        
        mockAnimeService.animeByStatus = [
            .watching: [],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.deleteAnime(userAnime)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockAnimeService.deleteAnimeCallCount, 1)
        XCTAssertEqual(mockAnimeService.lastDeletedAnimeId, 1)
        
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testDeleteAnimeReloadsLists() async throws {
        // Given
        let anime1 = createTestUserAnime(id: 1, anime: createTestAnime(id: 1, title: "Anime 1"), status: .watching)
        let anime2 = createTestUserAnime(id: 2, anime: createTestAnime(id: 2, title: "Anime 2"), status: .watching)
        
        // Initially two anime
        mockAnimeService.animeByStatus = [
            .watching: [anime1, anime2],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        viewModel.loadLists()
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(viewModel.watchingList.count, 2)
        
        // After delete, only one anime
        mockAnimeService.animeByStatus[.watching] = [anime2]
        
        // When
        viewModel.deleteAnime(anime1)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.watchingList.count, 1)
        XCTAssertEqual(viewModel.watchingList[0].id, 2)
    }
    
    func testDeleteAnimeHandlesError() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        let userAnime = createTestUserAnime(id: 1, anime: anime, status: .watching)
        
        mockAnimeService.shouldThrowError = KiroError.coreDataError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Delete failed"]
        ))
        
        // When
        viewModel.deleteAnime(userAnime)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Sync Tests
    
    func testSyncTriggersProcessSyncQueueAndSyncUserLists() async throws {
        // Given
        mockAnimeService.animeByStatus = [
            .watching: [],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.sync()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockSyncService.processSyncQueueCallCount, 1)
        XCTAssertEqual(mockSyncService.syncUserListsCallCount, 1)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testSyncReloadsLists() async throws {
        // Given
        let anime = createTestUserAnime(id: 1, anime: createTestAnime(id: 1, title: "Synced Anime"), status: .watching)
        
        mockAnimeService.animeByStatus = [
            .watching: [anime],
            .completed: [],
            .planToWatch: [],
            .onHold: [],
            .dropped: []
        ]
        
        // When
        viewModel.sync()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.watchingList.count, 1)
    }
    
    func testSyncHandlesError() async throws {
        // Given
        mockSyncService.shouldThrowError = KiroError.networkError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Sync failed"]
        ))
        
        // When
        viewModel.sync()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        if case .networkError = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected networkError")
        }
    }
}
