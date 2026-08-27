//
//  LibraryViewModel.swift
//  AniLedger
//
//  ViewModel for managing anime library lists and operations
//

import Foundation
import Combine

enum LibrarySortOption: String, CaseIterable, Identifiable {
    case custom = "Default Order"
    case titleAscending = "Title (A-Z)"
    case titleDescending = "Title (Z-A)"
    case scoreDescending = "Highest Score"
    case progressDescending = "Most Progress"
    
    var id: String { rawValue }
}

@MainActor
class LibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var watchingList: [UserAnime] = []
    @Published var completedList: [UserAnime] = []
    @Published var planToWatchList: [UserAnime] = []
    @Published var onHoldList: [UserAnime] = []
    @Published var droppedList: [UserAnime] = []
    @Published var searchQuery: String = ""
    @Published var sortOption: LibrarySortOption = .custom
    @Published var isLoading: Bool = false
    @Published var error: KiroError?
    
    // MARK: - Private Properties
    
    private var hasLoadedOnce = false
    
    // MARK: - Dependencies
    
    private let animeService: AnimeServiceProtocol
    private let syncService: SyncServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(animeService: AnimeServiceProtocol, syncService: SyncServiceProtocol) {
        self.animeService = animeService
        self.syncService = syncService
    }
    
    // MARK: - Filtered List Helper
    
    func filteredList(for status: AnimeStatus) -> [UserAnime] {
        let list: [UserAnime]
        switch status {
        case .watching: list = watchingList
        case .completed: list = completedList
        case .planToWatch: list = planToWatchList
        case .onHold: list = onHoldList
        case .dropped: list = droppedList
        }
        
        var result = list
        
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let query = trimmedQuery.lowercased()
            result = result.filter { item in
                item.anime.title.preferred.lowercased().contains(query) ||
                (item.anime.title.english?.lowercased().contains(query) ?? false) ||
                item.anime.title.romaji.lowercased().contains(query)
            }
        }
        
        switch sortOption {
        case .custom:
            break
        case .titleAscending:
            result.sort { $0.anime.title.preferred.localizedCaseInsensitiveCompare($1.anime.title.preferred) == .orderedAscending }
        case .titleDescending:
            result.sort { $0.anime.title.preferred.localizedCaseInsensitiveCompare($1.anime.title.preferred) == .orderedDescending }
        case .scoreDescending:
            result.sort { ($0.score ?? 0) > ($1.score ?? 0) }
        case .progressDescending:
            result.sort { $0.progress > $1.progress }
        }
        
        return result
    }
    
    // MARK: - Load Lists
    
    /// Loads all anime lists from Core Data
    func loadLists(forceRefresh: Bool = false) {
        // Skip if already loaded and not forcing refresh
        if hasLoadedOnce && !forceRefresh {
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                // Fetch anime for each status
                watchingList = try animeService.fetchAnimeByStatus(.watching)
                completedList = try animeService.fetchAnimeByStatus(.completed)
                planToWatchList = try animeService.fetchAnimeByStatus(.planToWatch)
                onHoldList = try animeService.fetchAnimeByStatus(.onHold)
                droppedList = try animeService.fetchAnimeByStatus(.dropped)
                
                hasLoadedOnce = true
                isLoading = false
            } catch let kiroError as KiroError {
                error = kiroError
                isLoading = false
            } catch {
                self.error = .coreDataError(underlying: error)
                isLoading = false
            }
        }
    }
    
    // MARK: - Move Anime
    
    /// Moves an anime to a different status list and syncs with AniList
    func moveAnime(_ anime: UserAnime, to status: AnimeStatus) {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Update status in Core Data
                _ = try animeService.moveAnimeBetweenLists(anime.id, toStatus: status)
                
                // Queue sync operation
                syncService.queueOperation(.updateStatus(mediaId: anime.anime.id, status: status.rawValue))
                
                // Trigger sync (non-blocking, will be debounced)
                Task.detached(priority: .background) {
                    try? await self.syncService.processSyncQueue()
                }
                
                // Reload lists to reflect changes
                loadLists(forceRefresh: true)
            } catch let kiroError as KiroError {
                error = kiroError
                isLoading = false
            } catch {
                self.error = .coreDataError(underlying: error)
                isLoading = false
            }
        }
    }
    
    // MARK: - Reorder Anime
    
    /// Reorders anime within a status list
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) {
        error = nil
        
        Task {
            do {
                try animeService.reorderAnime(in: status, from: sourceIndex, to: destinationIndex)
                
                // Reload the specific list to reflect changes
                switch status {
                case .watching:
                    watchingList = try animeService.fetchAnimeByStatus(.watching)
                case .completed:
                    completedList = try animeService.fetchAnimeByStatus(.completed)
                case .planToWatch:
                    planToWatchList = try animeService.fetchAnimeByStatus(.planToWatch)
                case .onHold:
                    onHoldList = try animeService.fetchAnimeByStatus(.onHold)
                case .dropped:
                    droppedList = try animeService.fetchAnimeByStatus(.dropped)
                }
            } catch let kiroError as KiroError {
                error = kiroError
            } catch {
                self.error = .coreDataError(underlying: error)
            }
        }
    }
    
    // MARK: - Delete Anime
    
    /// Deletes an anime from the library
    func deleteAnime(_ anime: UserAnime) {
        isLoading = true
        error = nil
        
        Task {
            do {
                try animeService.deleteAnimeFromLibrary(anime.id)
                
                // Queue delete operation for sync
                syncService.queueOperation(.deleteEntry(entryId: Int(anime.id), mediaId: anime.anime.id))
                
                // Reload lists to reflect changes
                loadLists(forceRefresh: true)
            } catch let kiroError as KiroError {
                error = kiroError
                isLoading = false
            } catch {
                self.error = .coreDataError(underlying: error)
                isLoading = false
            }
        }
    }
    
    // MARK: - Sync
    
    /// Triggers manual sync with AniList
    func sync() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Process any pending sync queue items
                try await syncService.processSyncQueue()
                
                // Perform incremental sync
                try await syncService.syncUserLists()
                
                // Reload lists to reflect synced changes
                loadLists(forceRefresh: true)
            } catch let kiroError as KiroError {
                error = kiroError
                isLoading = false
            } catch {
                self.error = .networkError(underlying: error)
                isLoading = false
            }
        }
    }
}
