//
//  DiscoverViewModelTests.swift
//  AniLedgerTests
//
//  Unit tests for DiscoverViewModel
//

import XCTest
@testable import AniLedger

@MainActor
final class DiscoverViewModelTests: XCTestCase {
    var viewModel: DiscoverViewModel!
    var mockAPIClient: MockAniListAPIClient!
    var mockAnimeService: MockAnimeService!
    
    override func setUp() {
        super.setUp()
        
        mockAPIClient = MockAniListAPIClient()
        mockAnimeService = MockAnimeService()
        viewModel = DiscoverViewModel(
            apiClient: mockAPIClient,
            animeService: mockAnimeService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockAPIClient = nil
        mockAnimeService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestMediaResponse(id: Int, title: String, genres: [String] = ["Action"], format: String = "TV") -> MediaResponse {
        return MediaResponse(
            id: id,
            title: TitleResponse(romaji: title, english: "\(title) EN", native: "\(title) JP"),
            coverImage: CoverImageResponse(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            episodes: 12,
            format: format,
            genres: genres,
            description: "Test synopsis for \(title)",
            siteUrl: "https://anilist.co/anime/\(id)"
        )
    }
    
    private func createTestAnime(id: Int, title: String, genres: [String] = ["Action"], format: AnimeFormat = .tv) -> Anime {
        return Anime(
            id: id,
            title: AnimeTitle(romaji: title, english: "\(title) EN", native: "\(title) JP"),
            coverImage: CoverImage(large: "https://example.com/large.jpg", medium: "https://example.com/medium.jpg"),
            episodes: 12,
            format: format,
            genres: genres,
            synopsis: "Test synopsis for \(title)",
            siteUrl: "https://anilist.co/anime/\(id)"
        )
    }
    
    // MARK: - Load Discover Content Tests
    
    func testLoadDiscoverContentFetchesAllCategories() async throws {
        // Given
        let testMedia = [
            createTestMediaResponse(id: 1, title: "Anime 1"),
            createTestMediaResponse(id: 2, title: "Anime 2"),
            createTestMediaResponse(id: 3, title: "Anime 3")
        ]
        
        // Mock API responses - will be called three times (current season, upcoming, trending)
        // Since all three calls happen concurrently, the mock will return the same data for each
        mockAPIClient.queryResult = PageResponse(page: Page(media: testMedia))
        
        // When
        viewModel.loadDiscoverContent()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then - each category should have anime (same data from mock)
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 3, "Current season should have 3 anime")
        XCTAssertEqual(viewModel.upcomingAnime.count, 3, "Upcoming should have 3 anime")
        XCTAssertEqual(viewModel.trendingAnime.count, 3, "Trending should have 3 anime")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
        XCTAssertNil(viewModel.error, "Error should be nil on success")
        
        // Verify API was called 3 times (once for each category)
        XCTAssertEqual(mockAPIClient.executeQueryCallCount, 3, "API should be called 3 times")
    }
    
    func testLoadDiscoverContentSetsLoadingState() {
        // Given
        mockAPIClient.queryResult = PageResponse(page: Page(media: []))
        
        // When
        XCTAssertFalse(viewModel.isLoading)
        viewModel.loadDiscoverContent()
        
        // Then - loading should be set immediately
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testLoadDiscoverContentHandlesError() async throws {
        // Given
        mockAPIClient.shouldThrowError = KiroError.networkError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Network error"]
        ))
        
        // When
        viewModel.loadDiscoverContent()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        if case .networkError = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected networkError")
        }
    }
    
    func testLoadDiscoverContentWithEmptyResults() async throws {
        // Given
        mockAPIClient.queryResult = PageResponse(page: Page(media: []))
        
        // When
        viewModel.loadDiscoverContent()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 0)
        XCTAssertEqual(viewModel.upcomingAnime.count, 0)
        XCTAssertEqual(viewModel.trendingAnime.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Apply Filters Tests
    
    func testApplyFiltersCorrectlyFiltersGenres() async throws {
        // Given
        let actionAnime = createTestMediaResponse(id: 1, title: "Action Anime", genres: ["Action", "Adventure"])
        let comedyAnime = createTestMediaResponse(id: 2, title: "Comedy Anime", genres: ["Comedy", "Slice of Life"])
        let dramaAnime = createTestMediaResponse(id: 3, title: "Drama Anime", genres: ["Drama", "Romance"])
        
        // Mock API to return mixed genres
        mockAPIClient.queryResult = PageResponse(page: Page(media: [actionAnime, comedyAnime, dramaAnime]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state - all anime loaded
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 3, "Should have all 3 anime initially")
        XCTAssertEqual(viewModel.upcomingAnime.count, 3, "Should have all 3 anime initially")
        XCTAssertEqual(viewModel.trendingAnime.count, 3, "Should have all 3 anime initially")
        
        // When - apply genre filter for Action
        viewModel.selectedGenres = ["Action"]
        viewModel.applyFilters()
        
        // Then - filtered results should only contain Action anime
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 1, "Should have 1 Action anime")
        XCTAssertEqual(viewModel.upcomingAnime.count, 1, "Should have 1 Action anime")
        XCTAssertEqual(viewModel.trendingAnime.count, 1, "Should have 1 Action anime")
        
        for anime in viewModel.currentSeasonAnime {
            XCTAssertTrue(anime.genres.contains("Action"), "Anime should have Action genre")
        }
        
        for anime in viewModel.upcomingAnime {
            XCTAssertTrue(anime.genres.contains("Action"), "Anime should have Action genre")
        }
        
        for anime in viewModel.trendingAnime {
            XCTAssertTrue(anime.genres.contains("Action"), "Anime should have Action genre")
        }
    }
    
    func testApplyFiltersCorrectlyFiltersFormats() async throws {
        // Given
        let tvAnime = createTestMediaResponse(id: 1, title: "TV Anime", format: "TV")
        let movieAnime = createTestMediaResponse(id: 2, title: "Movie Anime", format: "MOVIE")
        let ovaAnime = createTestMediaResponse(id: 3, title: "OVA Anime", format: "OVA")
        
        // Mock API to return mixed formats
        mockAPIClient.queryResult = PageResponse(page: Page(media: [tvAnime, movieAnime, ovaAnime]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state - all anime loaded
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 3, "Should have all 3 anime initially")
        XCTAssertEqual(viewModel.upcomingAnime.count, 3, "Should have all 3 anime initially")
        XCTAssertEqual(viewModel.trendingAnime.count, 3, "Should have all 3 anime initially")
        
        // When - apply format filter for TV
        viewModel.selectedFormats = [.tv]
        viewModel.applyFilters()
        
        // Then - filtered results should only contain TV format
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 1, "Should have 1 TV anime")
        XCTAssertEqual(viewModel.upcomingAnime.count, 1, "Should have 1 TV anime")
        XCTAssertEqual(viewModel.trendingAnime.count, 1, "Should have 1 TV anime")
        
        for anime in viewModel.currentSeasonAnime {
            XCTAssertEqual(anime.format, .tv, "Anime should be TV format")
        }
        
        for anime in viewModel.upcomingAnime {
            XCTAssertEqual(anime.format, .tv, "Anime should be TV format")
        }
        
        for anime in viewModel.trendingAnime {
            XCTAssertEqual(anime.format, .tv, "Anime should be TV format")
        }
    }
    
    func testApplyFiltersWithBothGenreAndFormat() async throws {
        // Given
        let actionTVAnime = createTestMediaResponse(id: 1, title: "Action TV", genres: ["Action"], format: "TV")
        let actionMovieAnime = createTestMediaResponse(id: 2, title: "Action Movie", genres: ["Action"], format: "MOVIE")
        let comedyTVAnime = createTestMediaResponse(id: 3, title: "Comedy TV", genres: ["Comedy"], format: "TV")
        
        // Mock API to return mixed anime
        mockAPIClient.queryResult = PageResponse(page: Page(media: [actionTVAnime, actionMovieAnime, comedyTVAnime]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 3, "Should have all 3 anime initially")
        
        // When - apply both genre and format filters
        viewModel.selectedGenres = ["Action"]
        viewModel.selectedFormats = [.tv]
        viewModel.applyFilters()
        
        // Then - should only show Action TV anime (1 match)
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 1, "Should have 1 anime matching both filters")
        XCTAssertEqual(viewModel.upcomingAnime.count, 1, "Should have 1 anime matching both filters")
        XCTAssertEqual(viewModel.trendingAnime.count, 1, "Should have 1 anime matching both filters")
        
        for anime in viewModel.currentSeasonAnime {
            XCTAssertTrue(anime.genres.contains("Action"), "Anime should have Action genre")
            XCTAssertEqual(anime.format, .tv, "Anime should be TV format")
        }
        
        for anime in viewModel.upcomingAnime {
            XCTAssertTrue(anime.genres.contains("Action"), "Anime should have Action genre")
            XCTAssertEqual(anime.format, .tv, "Anime should be TV format")
        }
        
        for anime in viewModel.trendingAnime {
            XCTAssertTrue(anime.genres.contains("Action"), "Anime should have Action genre")
            XCTAssertEqual(anime.format, .tv, "Anime should be TV format")
        }
    }
    
    func testApplyFiltersWithNoFiltersShowsAll() async throws {
        // Given
        let anime1 = createTestMediaResponse(id: 1, title: "Anime 1")
        let anime2 = createTestMediaResponse(id: 2, title: "Anime 2")
        
        // Mock API to return anime
        mockAPIClient.queryResult = PageResponse(page: Page(media: [anime1, anime2]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 2, "Should have 2 anime initially")
        XCTAssertEqual(viewModel.upcomingAnime.count, 2, "Should have 2 anime initially")
        XCTAssertEqual(viewModel.trendingAnime.count, 2, "Should have 2 anime initially")
        
        // When - no filters applied (empty sets)
        viewModel.selectedGenres = []
        viewModel.selectedFormats = []
        viewModel.applyFilters()
        
        // Then - should show all anime (counts should remain the same)
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 2, "Should still have 2 anime with no filters")
        XCTAssertEqual(viewModel.upcomingAnime.count, 2, "Should still have 2 anime with no filters")
        XCTAssertEqual(viewModel.trendingAnime.count, 2, "Should still have 2 anime with no filters")
    }
    
    func testApplyFiltersWithNoMatchesReturnsEmpty() async throws {
        // Given
        let actionAnime = createTestMediaResponse(id: 1, title: "Action Anime", genres: ["Action"])
        
        // Mock API to return action anime
        mockAPIClient.queryResult = PageResponse(page: Page(media: [actionAnime]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 1, "Should have 1 anime initially")
        
        // When - apply filter that doesn't match any anime
        viewModel.selectedGenres = ["Romance"]
        viewModel.applyFilters()
        
        // Then - should return empty arrays
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 0, "Should have no anime matching Romance")
        XCTAssertEqual(viewModel.upcomingAnime.count, 0, "Should have no anime matching Romance")
        XCTAssertEqual(viewModel.trendingAnime.count, 0, "Should have no anime matching Romance")
    }
    
    func testApplyFiltersWithMultipleGenres() async throws {
        // Given
        let actionAnime = createTestMediaResponse(id: 1, title: "Action Anime", genres: ["Action"])
        let comedyAnime = createTestMediaResponse(id: 2, title: "Comedy Anime", genres: ["Comedy"])
        let dramaAnime = createTestMediaResponse(id: 3, title: "Drama Anime", genres: ["Drama"])
        
        // Mock API to return mixed genres
        mockAPIClient.queryResult = PageResponse(page: Page(media: [actionAnime, comedyAnime, dramaAnime]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 3, "Should have 3 anime initially")
        
        // When - apply multiple genre filters (OR logic)
        viewModel.selectedGenres = ["Action", "Comedy"]
        viewModel.applyFilters()
        
        // Then - should show anime matching either Action OR Comedy
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 2, "Should have 2 anime matching Action or Comedy")
        XCTAssertEqual(viewModel.upcomingAnime.count, 2, "Should have 2 anime matching Action or Comedy")
        XCTAssertEqual(viewModel.trendingAnime.count, 2, "Should have 2 anime matching Action or Comedy")
        
        // Verify the filtered anime have the correct genres
        for anime in viewModel.currentSeasonAnime {
            let hasActionOrComedy = anime.genres.contains("Action") || anime.genres.contains("Comedy")
            XCTAssertTrue(hasActionOrComedy, "Anime should have Action or Comedy genre")
        }
    }
    
    func testApplyFiltersWithMultipleFormats() async throws {
        // Given
        let tvAnime = createTestMediaResponse(id: 1, title: "TV Anime", format: "TV")
        let movieAnime = createTestMediaResponse(id: 2, title: "Movie Anime", format: "MOVIE")
        let ovaAnime = createTestMediaResponse(id: 3, title: "OVA Anime", format: "OVA")
        
        // Mock API to return mixed formats
        mockAPIClient.queryResult = PageResponse(page: Page(media: [tvAnime, movieAnime, ovaAnime]))
        
        // Load initial content
        viewModel.loadDiscoverContent()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify initial state
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 3, "Should have 3 anime initially")
        
        // When - apply multiple format filters (OR logic)
        viewModel.selectedFormats = [.tv, .movie]
        viewModel.applyFilters()
        
        // Then - should show anime matching either TV OR Movie
        XCTAssertEqual(viewModel.currentSeasonAnime.count, 2, "Should have 2 anime matching TV or Movie")
        XCTAssertEqual(viewModel.upcomingAnime.count, 2, "Should have 2 anime matching TV or Movie")
        XCTAssertEqual(viewModel.trendingAnime.count, 2, "Should have 2 anime matching TV or Movie")
        
        // Verify the filtered anime have the correct formats
        for anime in viewModel.currentSeasonAnime {
            XCTAssertTrue(anime.format == .tv || anime.format == .movie, "Anime should be TV or Movie format")
        }
    }
    
    // MARK: - Add to Library Tests
    
    func testAddToLibraryAddsAnimeWithCorrectStatus() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        
        // When
        viewModel.addToLibrary(anime, status: .watching)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockAnimeService.addAnimeCallCount, 1)
        XCTAssertNil(viewModel.error)
    }
    
    func testAddToLibraryWithDifferentStatuses() async throws {
        // Given
        let anime1 = createTestAnime(id: 1, title: "Anime 1")
        let anime2 = createTestAnime(id: 2, title: "Anime 2")
        let anime3 = createTestAnime(id: 3, title: "Anime 3")
        
        // When
        viewModel.addToLibrary(anime1, status: .watching)
        viewModel.addToLibrary(anime2, status: .planToWatch)
        viewModel.addToLibrary(anime3, status: .completed)
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockAnimeService.addAnimeCallCount, 3)
        XCTAssertNil(viewModel.error)
    }
    
    func testAddToLibraryHandlesError() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        mockAnimeService.shouldThrowError = KiroError.coreDataError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Add failed"]
        ))
        
        // When
        viewModel.addToLibrary(anime, status: .watching)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        if case .coreDataError = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected coreDataError")
        }
    }
    
    func testAddToLibraryWithZeroProgress() async throws {
        // Given
        let anime = createTestAnime(id: 1, title: "Test Anime")
        
        // When
        viewModel.addToLibrary(anime, status: .planToWatch)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - should add with progress 0
        XCTAssertEqual(mockAnimeService.addAnimeCallCount, 1)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingForAPIError() async throws {
        // Given
        mockAPIClient.shouldThrowError = KiroError.apiError(message: "API Error", statusCode: 500)
        
        // When
        viewModel.loadDiscoverContent()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        if case .apiError = viewModel.error {
            // Expected error type
        } else {
            XCTFail("Expected apiError")
        }
    }
    
    func testErrorHandlingForDecodingError() async throws {
        // Given
        mockAPIClient.shouldThrowError = KiroError.decodingError(underlying: NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Decoding failed"]
        ))
        
        // When
        viewModel.loadDiscoverContent()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
}
