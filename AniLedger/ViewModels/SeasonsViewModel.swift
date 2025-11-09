//
//  SeasonsViewModel.swift
//  AniLedger
//
//  ViewModel for browsing anime by season and year
//

import Foundation
import Combine

@MainActor
class SeasonsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var seasonalAnime: [Anime] = []
    @Published var selectedSeason: AnimeSeason
    @Published var selectedYear: Int
    @Published var isLoading: Bool = false
    @Published var error: KiroError?
    
    // MARK: - Computed Properties
    
    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    // MARK: - Private Properties
    
    private let apiClient: AniListAPIClientProtocol
    private let cacheManager = CacheManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiClient: AniListAPIClientProtocol) {
        self.apiClient = apiClient
        
        // Initialize with current season and year
        let (season, year) = Self.getCurrentSeasonAndYear()
        self.selectedSeason = season
        self.selectedYear = year
        
        loadFromCache()
    }
    
    // MARK: - Load Seasonal Anime
    
    /// Loads cached data immediately if available
    private func loadFromCache() {
        let cacheKey = makeCacheKey()
        if let cached: [Anime] = cacheManager.get(forKey: cacheKey) {
            seasonalAnime = cached
        }
    }
    
    /// Loads anime for the selected season and year
    func loadSeasonalAnime(forceRefresh: Bool = false) {
        let cacheKey = makeCacheKey()
        
        // If we have cached data and not forcing refresh, skip loading
        if !forceRefresh && cacheManager.hasValidCache(forKey: cacheKey) {
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let query = SeasonalAnimeQuery(
                    season: selectedSeason.rawValue,
                    year: selectedYear
                )
                let response: PageResponse = try await apiClient.execute(query: query)
                let anime = response.Page.media.map { convertToAnime($0) }
                
                seasonalAnime = anime
                
                // Cache the results (10 minutes expiration)
                cacheManager.set(anime, forKey: cacheKey, expirationInterval: 600)
                
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
    
    /// Refresh content by clearing cache and reloading
    func refresh() {
        let cacheKey = makeCacheKey()
        cacheManager.clear(forKey: cacheKey)
        loadSeasonalAnime(forceRefresh: true)
    }
    
    // MARK: - Year Navigation
    
    func incrementYear() {
        guard selectedYear < currentYear else { return }
        selectedYear += 1
        loadSeasonalAnime()
    }
    
    func decrementYear() {
        // Allow going back to 1990 (when anime tracking became more common)
        guard selectedYear > 1990 else { return }
        selectedYear -= 1
        loadSeasonalAnime()
    }
    
    func jumpToCurrentSeason() {
        let (season, year) = Self.getCurrentSeasonAndYear()
        selectedSeason = season
        selectedYear = year
        loadSeasonalAnime()
    }
    
    // MARK: - Private Helper Methods
    
    private func makeCacheKey() -> String {
        "seasonal_\(selectedSeason.rawValue)_\(selectedYear)"
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
        
        let format = AnimeFormat(rawValue: mediaResponse.format ?? "") ?? .tv
        
        return Anime(
            id: mediaResponse.id,
            title: title,
            coverImage: coverImage,
            bannerImage: mediaResponse.bannerImage,
            episodes: mediaResponse.episodes,
            format: format,
            genres: mediaResponse.genres,
            synopsis: mediaResponse.description,
            siteUrl: mediaResponse.siteUrl
        )
    }
    
    static func getCurrentSeasonAndYear() -> (AnimeSeason, Int) {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        let season: AnimeSeason
        switch month {
        case 1...3:
            season = .winter
        case 4...6:
            season = .spring
        case 7...9:
            season = .summer
        case 10...12:
            season = .fall
        default:
            season = .winter
        }
        
        return (season, year)
    }
}
