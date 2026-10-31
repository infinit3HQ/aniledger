//
//  LibraryViewModel.swift
//  AniLedger
//
//  ViewModel for managing anime library lists and operations
//

import Foundation
import Combine
import CoreData

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
    /// Failure to read the local library. Replaces the list with an error screen.
    @Published var error: KiroError?
    /// Failure of an action or a sync. Shown as a banner above the list,
    /// because the local library is still valid.
    @Published var actionError: KiroError?
    
    // MARK: - Private Properties
    
    private var hasLoadedOnce = false
    
    // MARK: - Dependencies
    
    private let animeService: AnimeServiceProtocol
    private let syncService: SyncServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// - Parameter libraryChanges: Fires when library data changes in Core Data
    ///   (local edits from any screen, or a background sync merging AniList data).
    ///   The lists reload automatically, so a manual refresh isn't needed.
    init(
        animeService: AnimeServiceProtocol,
        syncService: SyncServiceProtocol,
        libraryChanges: AnyPublisher<Void, Never>? = nil
    ) {
        self.animeService = animeService
        self.syncService = syncService
        
        let changes = libraryChanges ?? Self.viewContextLibraryChanges(context: CoreDataStack.shared.viewContext)
        changes
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self, self.hasLoadedOnce else { return }
                self.reloadFromStore()
            }
            .store(in: &cancellables)
    }
    
    /// Changes to anime or library entries in the main Core Data context.
    /// Background syncs are merged into this context, so their results show up here too.
    static func viewContextLibraryChanges(
        context: NSManagedObjectContext
    ) -> AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .filter { notification in
                guard let info = notification.userInfo else { return false }
                if info[NSInvalidatedAllObjectsKey] != nil { return true }
                let keys = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, NSRefreshedObjectsKey]
                return keys.contains { key in
                    guard let objects = info[key] as? Set<NSManagedObject> else { return false }
                    return objects.contains { $0 is UserAnimeEntity || $0 is AnimeEntity }
                }
            }
            .map { _ in () }
            .eraseToAnyPublisher()
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
        reloadFromStore()
        isLoading = false
    }
    
    /// Re-reads the lists from Core Data without showing the loading state.
    private func reloadFromStore() {
        do {
            watchingList = try animeService.fetchAnimeByStatus(.watching)
            completedList = try animeService.fetchAnimeByStatus(.completed)
            planToWatchList = try animeService.fetchAnimeByStatus(.planToWatch)
            onHoldList = try animeService.fetchAnimeByStatus(.onHold)
            droppedList = try animeService.fetchAnimeByStatus(.dropped)
            
            hasLoadedOnce = true
            error = nil
        } catch let kiroError as KiroError {
            error = kiroError
        } catch {
            self.error = .coreDataError(underlying: error)
        }
    }
    
    /// Clears the action/sync error banner.
    func dismissActionError() {
        actionError = nil
    }
    
    // MARK: - Entry Lookup
    
    /// Returns the current local entry for an item from the displayed list.
    ///
    /// The list can be a little behind Core Data: after a sync, an entry's ID
    /// changes from a local placeholder to AniList's ID. Looking it up by media
    /// ID avoids "User anime not found" errors when acting on such an item.
    private func currentEntry(for anime: UserAnime) throws -> UserAnime {
        if let entry = try animeService.getUserAnime(byAnimeId: anime.anime.id) {
            return entry
        }
        throw KiroError.coreDataError(underlying: NSError(
            domain: "LibraryViewModel",
            code: 1002,
            userInfo: [NSLocalizedDescriptionKey: "This anime is no longer in your library."]
        ))
    }
    
    private func pushQueuedChanges() {
        Task.detached(priority: .background) { [syncService] in
            try? await syncService.processSyncQueue()
        }
    }
    
    private func report(_ error: Error) {
        if let kiroError = error as? KiroError {
            actionError = kiroError
        } else {
            actionError = .coreDataError(underlying: error)
        }
    }
    
    // MARK: - Move Anime
    
    /// Moves an anime to a different status list and syncs with AniList
    func moveAnime(_ anime: UserAnime, to status: AnimeStatus) {
        actionError = nil
        
        do {
            let entry = try currentEntry(for: anime)
            _ = try animeService.moveAnimeBetweenLists(entry.id, toStatus: status)
            syncService.queueOperation(.updateStatus(mediaId: anime.anime.id, status: status.rawValue))
            pushQueuedChanges()
        } catch {
            report(error)
        }
        
        // Show the current state, including when the item was already gone
        reloadFromStore()
    }
    
    // MARK: - Reorder Anime
    
    /// Reorders anime within a status list
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) {
        actionError = nil
        
        do {
            try animeService.reorderAnime(in: status, from: sourceIndex, to: destinationIndex)
        } catch {
            report(error)
        }
        
        reloadFromStore()
    }
    
    // MARK: - Delete Anime
    
    /// Deletes an anime from the library
    func deleteAnime(_ anime: UserAnime) {
        actionError = nil
        
        do {
            let entry = try currentEntry(for: anime)
            try animeService.deleteAnimeFromLibrary(entry.id)
            syncService.queueOperation(.deleteEntry(entryId: entry.id, mediaId: anime.anime.id))
            pushQueuedChanges()
        } catch {
            report(error)
        }
        
        reloadFromStore()
    }
    
    // MARK: - Sync
    
    /// Triggers manual sync with AniList
    func sync() {
        isLoading = true
        actionError = nil
        
        Task {
            do {
                // Process any pending sync queue items
                try await syncService.processSyncQueue()
                
                // Perform incremental sync
                try await syncService.syncUserLists()
            } catch {
                report(error)
            }
            
            // Local data is valid either way; show the latest
            reloadFromStore()
            isLoading = false
        }
    }
}
