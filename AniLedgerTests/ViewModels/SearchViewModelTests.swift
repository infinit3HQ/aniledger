//
//  SearchViewModelTests.swift
//  AniLedgerTests
//
//  Unit tests for SearchViewModel
//

import XCTest
@testable import AniLedger

@MainActor
class SearchViewModelTests: XCTestCase {
    var mockApiClient: MockAniListAPIClient!
    var mockAnimeService: MockAnimeService!
    var mockSyncService: MockSyncService!
    var sampleAnime: Anime!
    
    override func setUp() {
        super.setUp()
        mockApiClient = MockAniListAPIClient()
        mockAnimeService = MockAnimeService()
        mockSyncService = MockSyncService()
        
        sampleAnime = Anime(
            id: 1,
            title: AnimeTitle(romaji: "Demon Slayer", english: "Demon Slayer", native: "鬼滅の刃"),
            coverImage: CoverImage(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            bannerImage: "https://example.com/banner.jpg",
            episodes: 26,
            format: .tv,
            genres: ["Action", "Supernatural"],
            synopsis: "Tanjiro fights demons to cure his sister.",
            siteUrl: "https://anilist.co/anime/1"
        )
    }
    
    override func tearDown() {
        mockApiClient = nil
        mockAnimeService = nil
        mockSyncService = nil
        sampleAnime = nil
        super.tearDown()
    }
    
    func testSearchReturnsResults() async {
        let mediaResponse = MediaResponse(
            id: 1,
            title: TitleResponse(romaji: "Demon Slayer", english: "Demon Slayer", native: "鬼滅の刃"),
            coverImage: CoverImageResponse(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            bannerImage: "https://example.com/banner.jpg",
            episodes: 26,
            format: "TV",
            genres: ["Action", "Supernatural"],
            description: "Tanjiro fights demons to cure his sister.",
            siteUrl: "https://anilist.co/anime/1",
            nextAiringEpisode: nil
        )
        
        mockApiClient.queryResult = PageResponse(Page: Page(media: [mediaResponse]))
        
        let viewModel = SearchViewModel(
            apiClient: mockApiClient,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        await viewModel.search(query: "Demon")
        
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.id, 1)
        XCTAssertEqual(viewModel.searchResults.first?.title.preferred, "Demon Slayer")
    }
    
    func testClearSearch() {
        let viewModel = SearchViewModel(
            apiClient: mockApiClient,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        viewModel.searchText = "Demon"
        viewModel.searchResults = [sampleAnime]
        
        viewModel.clearSearch()
        
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.error)
    }
    
    func testAddToLibraryQueuesSync() {
        let viewModel = SearchViewModel(
            apiClient: mockApiClient,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
        
        viewModel.addToLibrary(sampleAnime, status: .watching)
        
        // Allow async Task to execute
        let expectation = XCTestExpectation(description: "Add to library")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockAnimeService.addAnimeCallCount, 1)
            XCTAssertEqual(self.mockSyncService.queueOperationCallCount, 1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
