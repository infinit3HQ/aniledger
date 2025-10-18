//
//  SearchViewModel.swift
//  AniLedger
//
//  ViewModel for searching anime by title
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var searchText: String = ""
    @Published var searchResults: [Anime] = []
    @Published var isLoading: Bool = false
    @Published var error: KiroError?
    
    // MARK: - Dependencies
    
    private let apiClient: AniListAPIClientProtocol
    private let animeService: AnimeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiClient: AniListAPIClientProtocol, animeService: AnimeServiceProtocol) {
        self.apiClient = apiClient
        self.animeService = animeService
        
        setupSearchDebouncing()
    }
    
    // MARK: - Setup Search Debouncing
    
    /// Sets up debounced search using Combine
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .seconds(Config.searchDebounceDelay), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self else { return }
                
                if searchTerm.isEmpty {
                    self.searchResults = []
                    self.error = nil
                } else {
                    Task {
                        await self.search(query: searchTerm)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search
    
    /// Searches for anime by title using AniList API
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let searchQuery = SearchAnimeQuery(searchTerm: query)
            let response: PageResponse = try await apiClient.execute(query: searchQuery)
            
            // Convert MediaResponse to Anime
            searchResults = response.Page.media.map { convertToAnime($0) }
            isLoading = false
        } catch let kiroError as KiroError {
            error = kiroError
            searchResults = []
            isLoading = false
        } catch {
            self.error = .networkError(underlying: error)
            searchResults = []
            isLoading = false
        }
    }
    
    // MARK: - Add to Library
    
    /// Adds an anime from search results to the user's library
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
    
    // MARK: - Clear Search
    
    /// Clears search results and search text
    func clearSearch() {
        searchText = ""
        searchResults = []
        error = nil
    }
    
    // MARK: - Private Helper Methods
    
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
            episodes: mediaResponse.episodes,
            format: format,
            genres: mediaResponse.genres,
            synopsis: mediaResponse.description,
            siteUrl: mediaResponse.siteUrl
        )
    }
}
