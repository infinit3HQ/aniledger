//
//  AnimeServiceTests.swift
//  AniLedgerTests
//
//  Created by Kiro on 10/13/2025.
//

import XCTest
import CoreData
@testable import AniLedger

final class AnimeServiceTests: XCTestCase {
    var animeService: AnimeService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory Core Data stack for testing
        coreDataStack = CoreDataStack(inMemory: true)
        animeService = AnimeService(coreDataStack: coreDataStack)
    }
    
    override func tearDown() {
        // Clean up
        try? coreDataStack.clearAllData()
        animeService = nil
        coreDataStack = nil
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
    
    // MARK: - Add Anime Tests
    
    func testAddAnimeToLibrary() throws {
        // Given
        let anime = createTestAnime()
        
        // When
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 0, score: nil)
        
        // Then
        XCTAssertEqual(userAnime.id, anime.id)
        XCTAssertEqual(userAnime.anime.id, anime.id)
        XCTAssertEqual(userAnime.status, .watching)
        XCTAssertEqual(userAnime.progress, 0)
        XCTAssertNil(userAnime.score)
        XCTAssertEqual(userAnime.sortOrder, 0)
        XCTAssertTrue(userAnime.needsSync)
    }
    
    func testAddAnimeToLibraryWithProgress() throws {
        // Given
        let anime = createTestAnime()
        
        // When
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 5, score: 8.5)
        
        // Then
        XCTAssertEqual(userAnime.progress, 5)
        XCTAssertEqual(userAnime.score, 8.5)
        XCTAssertTrue(userAnime.needsSync)
    }
    
    func testAddAnimeToLibraryWithCorrectSortOrder() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        let anime3 = createTestAnime(id: 3, title: "Anime 3")
        
        // When
        let userAnime1 = try animeService.addAnimeToLibrary(anime1, status: .watching)
        let userAnime2 = try animeService.addAnimeToLibrary(anime2, status: .watching)
        let userAnime3 = try animeService.addAnimeToLibrary(anime3, status: .watching)
        
        // Then
        XCTAssertEqual(userAnime1.sortOrder, 0)
        XCTAssertEqual(userAnime2.sortOrder, 1)
        XCTAssertEqual(userAnime3.sortOrder, 2)
    }
    
    func testAddDuplicateAnimeThrowsError() throws {
        // Given
        let anime = createTestAnime()
        _ = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When/Then
        XCTAssertThrowsError(try animeService.addAnimeToLibrary(anime, status: .completed)) { error in
            XCTAssertTrue(error is KiroError)
            if case .coreDataError = error as? KiroError {
                // Expected error
            } else {
                XCTFail("Expected coreDataError")
            }
        }
    }
    
    // MARK: - Update Progress Tests
    
    func testUpdateAnimeProgress() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 0)
        
        // When
        let updatedAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        
        // Then
        XCTAssertEqual(updatedAnime.progress, 5)
        XCTAssertTrue(updatedAnime.needsSync)
        XCTAssertNotEqual(updatedAnime.lastModified, userAnime.lastModified)
    }
    
    func testUpdateAnimeProgressMultipleTimes() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 0)
        
        // When
        _ = try animeService.updateAnimeProgress(userAnime.id, progress: 3)
        _ = try animeService.updateAnimeProgress(userAnime.id, progress: 7)
        let finalAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 12)
        
        // Then
        XCTAssertEqual(finalAnime.progress, 12)
        XCTAssertTrue(finalAnime.needsSync)
    }
    
    func testUpdateProgressForNonExistentAnimeThrowsError() throws {
        // When/Then
        XCTAssertThrowsError(try animeService.updateAnimeProgress(999, progress: 5)) { error in
            XCTAssertTrue(error is KiroError)
        }
    }
    
    // MARK: - Update Status Tests
    
    func testUpdateAnimeStatus() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 5)
        
        // When
        let updatedAnime = try animeService.updateAnimeStatus(userAnime.id, status: .completed)
        
        // Then
        XCTAssertEqual(updatedAnime.status, .completed)
        XCTAssertEqual(updatedAnime.progress, 5) // Progress should remain unchanged
        XCTAssertTrue(updatedAnime.needsSync)
    }
    
    func testUpdateStatusForNonExistentAnimeThrowsError() throws {
        // When/Then
        XCTAssertThrowsError(try animeService.updateAnimeStatus(999, status: .completed)) { error in
            XCTAssertTrue(error is KiroError)
        }
    }
    
    // MARK: - Update Score Tests
    
    func testUpdateAnimeScore() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let updatedAnime = try animeService.updateAnimeScore(userAnime.id, score: 9.0)
        
        // Then
        XCTAssertEqual(updatedAnime.score, 9.0)
        XCTAssertTrue(updatedAnime.needsSync)
    }
    
    func testUpdateAnimeScoreToNil() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, score: 8.0)
        
        // When
        let updatedAnime = try animeService.updateAnimeScore(userAnime.id, score: nil)
        
        // Then
        XCTAssertNil(updatedAnime.score)
        XCTAssertTrue(updatedAnime.needsSync)
    }
    
    // MARK: - Delete Anime Tests
    
    func testDeleteAnimeFromLibrary() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        try animeService.deleteAnimeFromLibrary(userAnime.id)
        
        // Then
        let fetchedAnime = try animeService.getUserAnime(byId: userAnime.id)
        XCTAssertNil(fetchedAnime)
    }
    
    func testDeleteNonExistentAnimeThrowsError() throws {
        // When/Then
        XCTAssertThrowsError(try animeService.deleteAnimeFromLibrary(999)) { error in
            XCTAssertTrue(error is KiroError)
        }
    }
    
    func testDeleteAnimeDoesNotAffectOtherAnime() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        let userAnime1 = try animeService.addAnimeToLibrary(anime1, status: .watching)
        let userAnime2 = try animeService.addAnimeToLibrary(anime2, status: .watching)
        
        // When
        try animeService.deleteAnimeFromLibrary(userAnime1.id)
        
        // Then
        let fetchedAnime1 = try animeService.getUserAnime(byId: userAnime1.id)
        let fetchedAnime2 = try animeService.getUserAnime(byId: userAnime2.id)
        XCTAssertNil(fetchedAnime1)
        XCTAssertNotNil(fetchedAnime2)
    }
    
    // MARK: - Fetch Anime Tests
    
    func testFetchAnimeByStatus() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Watching 1")
        let anime2 = createTestAnime(id: 2, title: "Watching 2")
        let anime3 = createTestAnime(id: 3, title: "Completed 1")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .completed)
        
        // When
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        let completedAnime = try animeService.fetchAnimeByStatus(.completed)
        
        // Then
        XCTAssertEqual(watchingAnime.count, 2)
        XCTAssertEqual(completedAnime.count, 1)
        XCTAssertTrue(watchingAnime.allSatisfy { $0.status == .watching })
        XCTAssertTrue(completedAnime.allSatisfy { $0.status == .completed })
    }
    
    func testFetchAnimeByStatusReturnsEmptyForNoMatches() throws {
        // Given
        let anime = createTestAnime()
        _ = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let droppedAnime = try animeService.fetchAnimeByStatus(.dropped)
        
        // Then
        XCTAssertEqual(droppedAnime.count, 0)
    }
    
    func testFetchAnimeByStatusReturnsSortedBySortOrder() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "First")
        let anime2 = createTestAnime(id: 2, title: "Second")
        let anime3 = createTestAnime(id: 3, title: "Third")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .watching)
        
        // When
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        
        // Then
        XCTAssertEqual(watchingAnime[0].sortOrder, 0)
        XCTAssertEqual(watchingAnime[1].sortOrder, 1)
        XCTAssertEqual(watchingAnime[2].sortOrder, 2)
    }
    
    func testFetchAllUserAnime() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        let anime3 = createTestAnime(id: 3, title: "Anime 3")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .completed)
        _ = try animeService.addAnimeToLibrary(anime3, status: .planToWatch)
        
        // When
        let allAnime = try animeService.fetchAllUserAnime()
        
        // Then
        XCTAssertEqual(allAnime.count, 3)
    }
    
    func testGetUserAnimeById() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let fetchedAnime = try animeService.getUserAnime(byId: userAnime.id)
        
        // Then
        XCTAssertNotNil(fetchedAnime)
        XCTAssertEqual(fetchedAnime?.id, userAnime.id)
        XCTAssertEqual(fetchedAnime?.anime.id, anime.id)
    }
    
    func testGetUserAnimeByIdReturnsNilForNonExistent() throws {
        // When
        let fetchedAnime = try animeService.getUserAnime(byId: 999)
        
        // Then
        XCTAssertNil(fetchedAnime)
    }
    
    func testGetUserAnimeByAnimeId() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let fetchedAnime = try animeService.getUserAnime(byAnimeId: anime.id)
        
        // Then
        XCTAssertNotNil(fetchedAnime)
        XCTAssertEqual(fetchedAnime?.anime.id, anime.id)
        XCTAssertEqual(fetchedAnime?.id, userAnime.id)
    }
    
    func testGetUserAnimeByAnimeIdReturnsNilForNonExistent() throws {
        // When
        let fetchedAnime = try animeService.getUserAnime(byAnimeId: 999)
        
        // Then
        XCTAssertNil(fetchedAnime)
    }
    
    // MARK: - Move Between Lists Tests
    
    func testMoveAnimeBetweenLists() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching, progress: 5)
        
        // When
        let movedAnime = try animeService.moveAnimeBetweenLists(userAnime.id, toStatus: .completed)
        
        // Then
        XCTAssertEqual(movedAnime.status, .completed)
        XCTAssertEqual(movedAnime.progress, 5) // Progress should remain unchanged
        XCTAssertTrue(movedAnime.needsSync)
        XCTAssertEqual(movedAnime.sortOrder, 0) // First item in completed list
    }
    
    func testMoveAnimeBetweenListsUpdatesOldListSortOrder() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        let anime3 = createTestAnime(id: 3, title: "Anime 3")
        
        let userAnime1 = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .watching)
        
        // When
        _ = try animeService.moveAnimeBetweenLists(userAnime1.id, toStatus: .completed)
        
        // Then
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        XCTAssertEqual(watchingAnime.count, 2)
        XCTAssertEqual(watchingAnime[0].sortOrder, 0)
        XCTAssertEqual(watchingAnime[1].sortOrder, 1)
    }
    
    func testMoveAnimeBetweenListsAssignsCorrectSortOrder() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Completed 1")
        let anime2 = createTestAnime(id: 2, title: "Completed 2")
        let anime3 = createTestAnime(id: 3, title: "Watching")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .completed)
        _ = try animeService.addAnimeToLibrary(anime2, status: .completed)
        let userAnime3 = try animeService.addAnimeToLibrary(anime3, status: .watching)
        
        // When
        let movedAnime = try animeService.moveAnimeBetweenLists(userAnime3.id, toStatus: .completed)
        
        // Then
        XCTAssertEqual(movedAnime.sortOrder, 2) // Should be added after existing completed anime
        
        let completedAnime = try animeService.fetchAnimeByStatus(.completed)
        XCTAssertEqual(completedAnime.count, 3)
    }
    
    func testMoveNonExistentAnimeThrowsError() throws {
        // When/Then
        XCTAssertThrowsError(try animeService.moveAnimeBetweenLists(999, toStatus: .completed)) { error in
            XCTAssertTrue(error is KiroError)
        }
    }
    
    // MARK: - Reorder Anime Tests
    
    func testReorderAnimeWithinList() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "First")
        let anime2 = createTestAnime(id: 2, title: "Second")
        let anime3 = createTestAnime(id: 3, title: "Third")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .watching)
        
        // When - Move first item to last position
        try animeService.reorderAnime(in: .watching, from: 0, to: 2)
        
        // Then
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        XCTAssertEqual(watchingAnime[0].anime.id, 2) // Second is now first
        XCTAssertEqual(watchingAnime[1].anime.id, 3) // Third is now second
        XCTAssertEqual(watchingAnime[2].anime.id, 1) // First is now last
        
        // Check sort orders are sequential
        XCTAssertEqual(watchingAnime[0].sortOrder, 0)
        XCTAssertEqual(watchingAnime[1].sortOrder, 1)
        XCTAssertEqual(watchingAnime[2].sortOrder, 2)
    }
    
    func testReorderAnimeFromLastToFirst() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "First")
        let anime2 = createTestAnime(id: 2, title: "Second")
        let anime3 = createTestAnime(id: 3, title: "Third")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .watching)
        
        // When - Move last item to first position
        try animeService.reorderAnime(in: .watching, from: 2, to: 0)
        
        // Then
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        XCTAssertEqual(watchingAnime[0].anime.id, 3) // Third is now first
        XCTAssertEqual(watchingAnime[1].anime.id, 1) // First is now second
        XCTAssertEqual(watchingAnime[2].anime.id, 2) // Second is now last
    }
    
    func testReorderAnimeInMiddle() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "First")
        let anime2 = createTestAnime(id: 2, title: "Second")
        let anime3 = createTestAnime(id: 3, title: "Third")
        let anime4 = createTestAnime(id: 4, title: "Fourth")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime4, status: .watching)
        
        // When - Move second item to third position
        try animeService.reorderAnime(in: .watching, from: 1, to: 2)
        
        // Then
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        XCTAssertEqual(watchingAnime[0].anime.id, 1)
        XCTAssertEqual(watchingAnime[1].anime.id, 3)
        XCTAssertEqual(watchingAnime[2].anime.id, 2)
        XCTAssertEqual(watchingAnime[3].anime.id, 4)
    }
    
    func testReorderAnimeWithInvalidSourceIndexThrowsError() throws {
        // Given
        let anime = createTestAnime()
        _ = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When/Then
        XCTAssertThrowsError(try animeService.reorderAnime(in: .watching, from: 5, to: 0)) { error in
            XCTAssertTrue(error is KiroError)
        }
    }
    
    func testReorderAnimeWithInvalidDestinationIndexThrowsError() throws {
        // Given
        let anime = createTestAnime()
        _ = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When/Then
        XCTAssertThrowsError(try animeService.reorderAnime(in: .watching, from: 0, to: 5)) { error in
            XCTAssertTrue(error is KiroError)
        }
    }
    
    func testReorderAnimeDoesNotAffectOtherLists() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Watching 1")
        let anime2 = createTestAnime(id: 2, title: "Watching 2")
        let anime3 = createTestAnime(id: 3, title: "Completed 1")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .completed)
        
        // When
        try animeService.reorderAnime(in: .watching, from: 0, to: 1)
        
        // Then
        let completedAnime = try animeService.fetchAnimeByStatus(.completed)
        XCTAssertEqual(completedAnime.count, 1)
        XCTAssertEqual(completedAnime[0].sortOrder, 0)
    }
    
    // MARK: - NeedsSync Flag Tests
    
    func testAddAnimeSetsSyncFlag() throws {
        // Given
        let anime = createTestAnime()
        
        // When
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // Then
        XCTAssertTrue(userAnime.needsSync)
    }
    
    func testUpdateProgressSetsSyncFlag() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let updatedAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        
        // Then
        XCTAssertTrue(updatedAnime.needsSync)
    }
    
    func testUpdateStatusSetsSyncFlag() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let updatedAnime = try animeService.updateAnimeStatus(userAnime.id, status: .completed)
        
        // Then
        XCTAssertTrue(updatedAnime.needsSync)
    }
    
    func testUpdateScoreSetsSyncFlag() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let updatedAnime = try animeService.updateAnimeScore(userAnime.id, score: 9.0)
        
        // Then
        XCTAssertTrue(updatedAnime.needsSync)
    }
    
    func testMoveAnimeBetweenListsSetsSyncFlag() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // When
        let movedAnime = try animeService.moveAnimeBetweenLists(userAnime.id, toStatus: .completed)
        
        // Then
        XCTAssertTrue(movedAnime.needsSync)
    }
    
    func testReorderAnimeSetsSyncFlag() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "First")
        let anime2 = createTestAnime(id: 2, title: "Second")
        
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        
        // When
        try animeService.reorderAnime(in: .watching, from: 0, to: 1)
        
        // Then
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        XCTAssertTrue(watchingAnime.allSatisfy { $0.needsSync })
    }
    
    // MARK: - Genre Tests
    
    func testAnimeGenresArePersisted() throws {
        // Given
        let anime = createTestAnime()
        
        // When
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // Then
        XCTAssertEqual(userAnime.anime.genres.count, 2)
        XCTAssertTrue(userAnime.anime.genres.contains("Action"))
        XCTAssertTrue(userAnime.anime.genres.contains("Adventure"))
    }
    
    func testAnimeWithNoGenres() throws {
        // Given
        var anime = createTestAnime()
        anime = Anime(
            id: anime.id,
            title: anime.title,
            coverImage: anime.coverImage,
            episodes: anime.episodes,
            format: anime.format,
            genres: [],
            synopsis: anime.synopsis,
            siteUrl: anime.siteUrl
        )
        
        // When
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        
        // Then
        XCTAssertEqual(userAnime.anime.genres.count, 0)
    }
    
    // MARK: - Last Modified Tests
    
    func testLastModifiedIsUpdatedOnProgressChange() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        let originalLastModified = userAnime.lastModified
        
        // Wait a bit to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.1)
        
        // When
        let updatedAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 5)
        
        // Then
        XCTAssertGreaterThan(updatedAnime.lastModified, originalLastModified)
    }
    
    func testLastModifiedIsUpdatedOnStatusChange() throws {
        // Given
        let anime = createTestAnime()
        let userAnime = try animeService.addAnimeToLibrary(anime, status: .watching)
        let originalLastModified = userAnime.lastModified
        
        // Wait a bit to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.1)
        
        // When
        let updatedAnime = try animeService.updateAnimeStatus(userAnime.id, status: .completed)
        
        // Then
        XCTAssertGreaterThan(updatedAnime.lastModified, originalLastModified)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() throws {
        // Given
        let anime = createTestAnime()
        
        // When - Add anime
        var userAnime = try animeService.addAnimeToLibrary(anime, status: .planToWatch)
        XCTAssertEqual(userAnime.status, .planToWatch)
        XCTAssertEqual(userAnime.progress, 0)
        
        // When - Start watching
        userAnime = try animeService.moveAnimeBetweenLists(userAnime.id, toStatus: .watching)
        XCTAssertEqual(userAnime.status, .watching)
        
        // When - Update progress
        userAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 6)
        XCTAssertEqual(userAnime.progress, 6)
        
        // When - Complete anime
        userAnime = try animeService.moveAnimeBetweenLists(userAnime.id, toStatus: .completed)
        userAnime = try animeService.updateAnimeProgress(userAnime.id, progress: 12)
        userAnime = try animeService.updateAnimeScore(userAnime.id, score: 9.5)
        
        // Then
        XCTAssertEqual(userAnime.status, .completed)
        XCTAssertEqual(userAnime.progress, 12)
        XCTAssertEqual(userAnime.score, 9.5)
        XCTAssertTrue(userAnime.needsSync)
    }
    
    func testMultipleAnimeInDifferentLists() throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Watching 1")
        let anime2 = createTestAnime(id: 2, title: "Watching 2")
        let anime3 = createTestAnime(id: 3, title: "Completed 1")
        let anime4 = createTestAnime(id: 4, title: "Plan to Watch 1")
        let anime5 = createTestAnime(id: 5, title: "On Hold 1")
        
        // When
        _ = try animeService.addAnimeToLibrary(anime1, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime2, status: .watching)
        _ = try animeService.addAnimeToLibrary(anime3, status: .completed)
        _ = try animeService.addAnimeToLibrary(anime4, status: .planToWatch)
        _ = try animeService.addAnimeToLibrary(anime5, status: .onHold)
        
        // Then
        let watching = try animeService.fetchAnimeByStatus(.watching)
        let completed = try animeService.fetchAnimeByStatus(.completed)
        let planToWatch = try animeService.fetchAnimeByStatus(.planToWatch)
        let onHold = try animeService.fetchAnimeByStatus(.onHold)
        let dropped = try animeService.fetchAnimeByStatus(.dropped)
        
        XCTAssertEqual(watching.count, 2)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(planToWatch.count, 1)
        XCTAssertEqual(onHold.count, 1)
        XCTAssertEqual(dropped.count, 0)
        
        let allAnime = try animeService.fetchAllUserAnime()
        XCTAssertEqual(allAnime.count, 5)
    }
}
