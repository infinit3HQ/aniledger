//
//  DiscoverViewModel.swift
//  AniLedger
//
//  ViewModel for discovering new anime (seasonal, upcoming, trending)
//

import Foundation
import Combine

@MainActor
class DiscoverViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentSeasonAnime: [Anime] = []
    @Published var upcomingAnime: [Anime] = []
    @Published var trendingAnime: [Anime] = []
    @Published var selectedGenres: Set<String> = []
    @Published var selectedFormats: Set<AnimeFormat> = []
    @Published var isLoading: Bool = false
    @Published var error: KiroError?
    
    // MARK: - Private Properties
    
    private var allCurrentSeasonAnime: [Anime] = []
    private var allUpcomingAnime: [Anime] = []
    private var allTrendingAnime: [Anime] = []
    
    // MARK: - Dependencies
    
    private let apiClient: AniListAPIClientProtocol
    private let animeService: AnimeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiClient: AniListAPIClientProtocol, animeService: AnimeServiceProtocol) {
        self.apiClient = apiClient
        self.animeService = animeService
    }
    
    // MARK: - Load Discover Content
    
    /// Loads all discover content: current season, upcoming, and trending anime
    func loadDiscoverContent() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Fetch all three categories concurrently
                async let currentSeason = fetchCurrentSeasonAnime()
                async let upcoming = fetchUpcomingAnime()
                async let trending = fetchTrendingAnime()
                
                let (currentSeasonResult, upcomingResult, trendingResult) = try await (currentSeason, upcoming, trending)
                
                // Store unfiltered results
                allCurrentSeasonAnime = currentSeasonResult
                allUpcomingAnime = upcomingResult
                allTrendingAnime = trendingResult
                
                // Apply any active filters
                applyFilters()
                
                isLoading = false
            } catch let kiroError as KiroError {
                error = kiroError
                isLoading = false
            } catch {
                self.error = .networkError(underlying: error)
                isLoading = false
            }
        }
    }
    
    // MARK: - Apply Filters
    
    /// Applies genre and format filters to the discover content
    func applyFilters() {
        // Filter current season anime
        currentSeasonAnime = filterAnime(allCurrentSeasonAnime)
        
        // Filter upcoming anime
        upcomingAnime = filterAnime(allUpcomingAnime)
        
        // Filter trending anime
        trendingAnime = filterAnime(allTrendingAnime)
    }
    
    // MARK: - Add to Library
    
    /// Adds an anime to the user's library with the specified status
    func addToLibrary(_ anime: Anime, status: AnimeStatus) {
        Task {
            do {
                _ = try animeService.addAnimeToLibrary(anime, status: status, progress: 0, score: nil)
            } catch let kiroError as KiroError {
                error = kiroError
            } catch {
                self.error = .coreDataError(underlying: error)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchCurrentSeasonAnime() async throws -> [Anime] {
        let (season, year) = getCurrentSeason()
        let query = SeasonalAnimeQuery(season: season, year: year)
        let response: PageResponse = try await apiClient.execute(query: query)
        return response.Page.media.map { convertToAnime($0) }
    }
    
    private func fetchUpcomingAnime() async throws -> [Anime] {
        let (season, year) = getNextSeason()
        let query = SeasonalAnimeQuery(season: season, year: year)
        let response: PageResponse = try await apiClient.execute(query: query)
        return response.Page.media.map { convertToAnime($0) }
    }
    
    private func fetchTrendingAnime() async throws -> [Anime] {
        let query = TrendingAnimeQuery()
        let response: PageResponse = try await apiClient.execute(query: query)
        return response.Page.media.map { convertToAnime($0) }
    }
    
    private func filterAnime(_ animeList: [Anime]) -> [Anime] {
        var filtered = animeList
        
        // Apply genre filter
        if !selectedGenres.isEmpty {
            filtered = filtered.filter { anime in
                !Set(anime.genres).isDisjoint(with: selectedGenres)
            }
        }
        
        // Apply format filter
        if !selectedFormats.isEmpty {
            filtered = filtered.filter { anime in
                selectedFormats.contains(anime.format)
            }
        }
        
        return filtered
    }
    
    private func convertToAnime(_ mediaResponse: MediaResponse) -> Anime {
        let title = AnimeTitle(
            romaji: mediaResponse.title.romaji,
            english: mediaResponse.title.english,
            native: mediaResponse.title.native
        )
        
        let coverImage = CoverImage(
            large: mediaResponse.coverImage.large,
            medium: mediaResponse.coverImage.medium
        )
        
        let format = AnimeFormat(rawValue: mediaResponse.format) ?? .tv
        
        return Anime(
            id: mediaResponse.id,
            title: title,
            coverImage: coverImage,
            episodes: mediaResponse.episodes,
            format: format,
            genres: mediaResponse.genres,
            synopsis: mediaResponse.description,
            siteUrl: mediaResponse.siteUrl
        )
    }
    
    private func getCurrentSeason() -> (String, Int) {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        let season: String
        switch month {
        case 1...3:
            season = "WINTER"
        case 4...6:
            season = "SPRING"
        case 7...9:
            season = "SUMMER"
        case 10...12:
            season = "FALL"
        default:
            season = "WINTER"
        }
        
        return (season, year)
    }
    
    private func getNextSeason() -> (String, Int) {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        var year = calendar.component(.year, from: now)
        
        let season: String
        switch month {
        case 1...3:
            season = "SPRING"
        case 4...6:
            season = "SUMMER"
        case 7...9:
            season = "FALL"
        case 10...12:
            season = "WINTER"
            year += 1 // Winter of next year
        default:
            season = "SPRING"
        }
        
        return (season, year)
    }
}
