//
//  SeasonsViewModelTests.swift
//  AniLedgerTests
//
//  Unit tests for SeasonsViewModel
//

import XCTest
@testable import AniLedger

@MainActor
class SeasonsViewModelTests: XCTestCase {
    var mockApiClient: MockAniListAPIClient!
    
    override func setUp() {
        super.setUp()
        mockApiClient = MockAniListAPIClient()
    }
    
    override func tearDown() {
        mockApiClient = nil
        super.tearDown()
    }
    
    func testYearIncrementAllowsUpcomingYear() {
        let viewModel = SeasonsViewModel(apiClient: mockApiClient)
        let currentYear = viewModel.currentYear
        viewModel.selectedYear = currentYear
        
        viewModel.incrementYear()
        
        XCTAssertEqual(viewModel.selectedYear, currentYear + 1)
        
        // Trying to increment beyond currentYear + 1 should be blocked
        viewModel.incrementYear()
        XCTAssertEqual(viewModel.selectedYear, currentYear + 1)
    }
    
    func testYearDecrement() {
        let viewModel = SeasonsViewModel(apiClient: mockApiClient)
        viewModel.selectedYear = 2024
        
        viewModel.decrementYear()
        
        XCTAssertEqual(viewModel.selectedYear, 2023)
    }
    
    func testLoadSeasonalAnime() async {
        let mediaResponse = MediaResponse(
            id: 1,
            title: TitleResponse(romaji: "Frieren", english: "Frieren: Beyond Journey's End", native: "葬送のフリーレン"),
            coverImage: CoverImageResponse(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            bannerImage: "https://example.com/banner.jpg",
            episodes: 28,
            format: "TV",
            genres: ["Adventure", "Fantasy"],
            description: "An elf mage re-examines life.",
            siteUrl: "https://anilist.co/anime/1",
            nextAiringEpisode: nil
        )
        
        mockApiClient.queryResult = PageResponse(Page: Page(media: [mediaResponse]))
        
        let viewModel = SeasonsViewModel(apiClient: mockApiClient)
        viewModel.loadSeasonalAnime(forceRefresh: true)
        
        // Wait for async load
        let expectation = XCTestExpectation(description: "Load seasonal anime")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.seasonalAnime.count, 1)
            XCTAssertEqual(viewModel.seasonalAnime.first?.title.preferred, "Frieren: Beyond Journey's End")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
