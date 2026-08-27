//
//  AiringScheduleServiceTests.swift
//  AniLedgerTests
//
//  Unit tests for AiringScheduleService
//

import XCTest
@testable import AniLedger

class AiringScheduleServiceTests: XCTestCase {
    var mockAnimeService: MockAnimeService!
    var mockNotificationService: MockNotificationService!
    var mockApiClient: MockAniListAPIClient!
    var service: AiringScheduleService!
    var sampleAnime: Anime!
    var sampleUserAnime: UserAnime!
    
    override func setUp() {
        super.setUp()
        mockAnimeService = MockAnimeService()
        mockNotificationService = MockNotificationService()
        mockApiClient = MockAniListAPIClient()
        service = AiringScheduleService(
            animeService: mockAnimeService,
            notificationService: mockNotificationService,
            apiClient: mockApiClient
        )
        
        sampleAnime = Anime(
            id: 1,
            title: AnimeTitle(romaji: "Jujutsu Kaisen", english: "Jujutsu Kaisen", native: "呪術廻戦"),
            coverImage: CoverImage(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            bannerImage: "https://example.com/banner.jpg",
            episodes: 24,
            format: .tv,
            genres: ["Action", "Fantasy"],
            synopsis: "Sorcerers fight curses.",
            siteUrl: "https://anilist.co/anime/1"
        )
        
        sampleUserAnime = UserAnime(
            id: 100,
            anime: sampleAnime,
            status: .watching,
            progress: 5,
            score: 9.0,
            sortOrder: 0,
            needsSync: false,
            lastModified: Date()
        )
    }
    
    override func tearDown() {
        service.stopMonitoring()
        mockAnimeService = nil
        mockNotificationService = nil
        mockApiClient = nil
        service = nil
        sampleAnime = nil
        sampleUserAnime = nil
        super.tearDown()
    }
    
    func testCheckForNewEpisodesSchedulesNotification() async throws {
        mockAnimeService.animeByStatus[.watching] = [sampleUserAnime]
        
        let airingTimestamp = Int(Date().addingTimeInterval(86400).timeIntervalSince1970) // 1 day in future
        let detail = MediaDetail(
            id: 1,
            nextAiringEpisode: AiringEpisode(
                airingAt: airingTimestamp,
                timeUntilAiring: 86400,
                episode: 6
            )
        )
        mockApiClient.queryResult = MediaDetailResponse(Media: detail)
        
        try await service.checkForNewEpisodes()
        
        XCTAssertEqual(mockAnimeService.fetchAnimeByStatusCallCount, 1)
        XCTAssertEqual(mockApiClient.executeQueryCallCount, 1)
        XCTAssertEqual(mockNotificationService.scheduleAiringNotificationCallCount, 1)
    }
    
    func testCheckForNewEpisodesResilienceOnError() async throws {
        let anime2 = Anime(
            id: 2,
            title: AnimeTitle(romaji: "Chainsaw Man", english: "Chainsaw Man", native: "チェンソーマン"),
            coverImage: CoverImage(large: "https://example.com/large2.jpg", medium: "https://example.com/medium2.jpg"),
            bannerImage: nil,
            episodes: 12,
            format: .tv,
            genres: ["Action"],
            synopsis: "Denji transforms into Chainsaw Man.",
            siteUrl: "https://anilist.co/anime/2"
        )
        let userAnime2 = UserAnime(
            id: 101,
            anime: anime2,
            status: .watching,
            progress: 3,
            score: 8.0,
            sortOrder: 1,
            needsSync: false,
            lastModified: Date()
        )
        
        mockAnimeService.animeByStatus[.watching] = [sampleUserAnime, userAnime2]
        
        // Throw error on query
        mockApiClient.shouldThrowError = AniLedgerError.invalidResponse
        
        // Should not throw or crash, loop should handle gracefully
        try await service.checkForNewEpisodes()
        
        XCTAssertEqual(mockAnimeService.fetchAnimeByStatusCallCount, 1)
    }
}
