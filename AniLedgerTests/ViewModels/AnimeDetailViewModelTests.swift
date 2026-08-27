//
//  AnimeDetailViewModelTests.swift
//  AniLedgerTests
//
//  Unit tests for AnimeDetailViewModel
//

import XCTest
@testable import AniLedger

@MainActor
class AnimeDetailViewModelTests: XCTestCase {
    var mockAnimeService: MockAnimeService!
    var mockSyncService: MockSyncService!
    var sampleAnime: Anime!
    var sampleUserAnime: UserAnime!
    
    override func setUp() {
        super.setUp()
        mockAnimeService = MockAnimeService()
        mockSyncService = MockSyncService()
        
        sampleAnime = Anime(
            id: 1,
            title: AnimeTitle(romaji: "Attack on Titan", english: "Attack on Titan", native: "進撃の巨人"),
            coverImage: CoverImage(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            bannerImage: "https://example.com/banner.jpg",
            episodes: 25,
            format: .tv,
            genres: ["Action", "Drama"],
            synopsis: "Humanity fights for survival against giant humanoids.",
            siteUrl: "https://anilist.co/anime/1"
        )
        
        sampleUserAnime = UserAnime(
            id: 100,
            anime: sampleAnime,
            status: .watching,
            progress: 10,
            score: 8.5,
            sortOrder: 0,
            needsSync: false,
            lastModified: Date()
        )
    }
    
    override func tearDown() {
        mockAnimeService = nil
        mockSyncService = nil
        sampleAnime = nil
        sampleUserAnime = nil
        super.tearDown()
    }
    
    // MARK: - Progress Tests
    
    func testIncrementProgress() async {
        mockAnimeService.animeByStatus[.watching] = [sampleUserAnime]
        let viewModel = AnimeDetailViewModel(
            anime: sampleAnime,
            userAnime: sampleUserAnime,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        await viewModel.updateProgress(11)
        
        XCTAssertEqual(mockAnimeService.updateProgressCallCount, 1)
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
        XCTAssertEqual(viewModel.userAnime?.progress, 11)
    }
    
    func testCompletionPromptTriggeredOnFinalEpisode() {
        let viewModel = AnimeDetailViewModel(
            anime: sampleAnime,
            userAnime: sampleUserAnime,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        // Progress to last episode (25)
        viewModel.userAnime = UserAnime(
            id: 100,
            anime: sampleAnime,
            status: .watching,
            progress: 24,
            score: 8.5,
            sortOrder: 0,
            needsSync: false,
            lastModified: Date()
        )
        
        viewModel.incrementProgress()
        
        XCTAssertTrue(viewModel.showCompletionPrompt)
    }
    
    // MARK: - Status Tests
    
    func testUpdateStatus() async {
        mockAnimeService.animeByStatus[.watching] = [sampleUserAnime]
        let viewModel = AnimeDetailViewModel(
            anime: sampleAnime,
            userAnime: sampleUserAnime,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        await viewModel.updateStatus(.completed)
        
        XCTAssertEqual(mockAnimeService.updateStatusCallCount, 1)
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
        XCTAssertEqual(viewModel.userAnime?.status, .completed)
    }
    
    // MARK: - Score Tests
    
    func testUpdateScore() async {
        mockAnimeService.animeByStatus[.watching] = [sampleUserAnime]
        let viewModel = AnimeDetailViewModel(
            anime: sampleAnime,
            userAnime: sampleUserAnime,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        await viewModel.updateScore(9.5)
        
        XCTAssertEqual(mockAnimeService.updateScoreCallCount, 1)
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
        XCTAssertEqual(viewModel.userAnime?.score, 9.5)
    }
    
    // MARK: - Library Management Tests
    
    func testAddToLibraryQueuesSync() async {
        let viewModel = AnimeDetailViewModel(
            anime: sampleAnime,
            userAnime: nil,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        XCTAssertFalse(viewModel.isInLibrary)
        
        await viewModel.addToLibrary(status: .planToWatch)
        
        XCTAssertTrue(viewModel.isInLibrary)
        XCTAssertEqual(mockAnimeService.addAnimeCallCount, 1)
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
    }
    
    func testRemoveFromLibraryQueuesSync() async {
        mockAnimeService.animeByStatus[.watching] = [sampleUserAnime]
        let viewModel = AnimeDetailViewModel(
            anime: sampleAnime,
            userAnime: sampleUserAnime,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        XCTAssertTrue(viewModel.isInLibrary)
        
        await viewModel.removeFromLibrary()
        
        XCTAssertFalse(viewModel.isInLibrary)
        XCTAssertNil(viewModel.userAnime)
        XCTAssertEqual(mockAnimeService.deleteAnimeCallCount, 1)
        XCTAssertEqual(mockSyncService.queueOperationCallCount, 1)
    }
}
