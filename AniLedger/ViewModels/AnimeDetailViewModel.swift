//
//  AnimeDetailViewModel.swift
//  AniLedger
//
//  ViewModel for anime detail view
//

import Foundation
import Combine
import AppKit

@MainActor
class AnimeDetailViewModel: ObservableObject {
    @Published var anime: Anime
    @Published var userAnime: UserAnime?
    @Published var isInLibrary: Bool = false
    @Published var isUpdating: Bool = false
    @Published var error: KiroError?
    @Published var showCompletionPrompt: Bool = false
    
    private let animeService: AnimeServiceProtocol
    private let syncService: SyncServiceProtocol
    
    init(anime: Anime, userAnime: UserAnime? = nil, animeService: AnimeServiceProtocol, syncService: SyncServiceProtocol) {
        self.anime = anime
        self.userAnime = userAnime
        self.isInLibrary = userAnime != nil
        self.animeService = animeService
        self.syncService = syncService
    }
    
    // MARK: - Progress Management
    
    func incrementProgress() {
        guard let userAnime = userAnime else { return }
        
        let newProgress = userAnime.progress + 1
        
        // Check if reaching final episode
        if let episodes = anime.episodes, newProgress >= episodes {
            showCompletionPrompt = true
        }
        
        Task {
            await updateProgress(newProgress)
        }
    }
    
    func decrementProgress() {
        guard let userAnime = userAnime else { return }
        
        // Don't allow negative progress
        let newProgress = max(0, userAnime.progress - 1)
        
        Task {
            await updateProgress(newProgress)
        }
    }
    
    func updateProgress(_ newProgress: Int) async {
        guard let userAnime = userAnime else { return }
        
        isUpdating = true
        error = nil
        
        do {
            let updated = try animeService.updateAnimeProgress(userAnime.id, progress: newProgress)
            self.userAnime = updated
            
            // Queue the operation for sync
            syncService.queueOperation(.updateProgress(
                mediaId: anime.id,
                progress: newProgress,
                status: updated.status.rawValue
            ))
            
            // Trigger sync (non-blocking, will be debounced)
            Task.detached(priority: .background) {
                try? await self.syncService.processSyncQueue()
            }
        } catch let kiroError as KiroError {
            error = kiroError
        } catch {
            self.error = .coreDataError(underlying: error)
        }
        
        isUpdating = false
    }
    
    // MARK: - Status Management
    
    func updateStatus(_ newStatus: AnimeStatus) async {
        guard let userAnime = userAnime else { return }
        
        isUpdating = true
        error = nil
        
        do {
            let updated = try animeService.updateAnimeStatus(userAnime.id, status: newStatus)
            self.userAnime = updated
            
            // Queue the operation for sync
            syncService.queueOperation(.updateStatus(
                mediaId: anime.id,
                status: newStatus.rawValue
            ))
            
            // Trigger sync (non-blocking, will be debounced)
            Task.detached(priority: .background) {
                try? await self.syncService.processSyncQueue()
            }
        } catch let kiroError as KiroError {
            error = kiroError
        } catch {
            self.error = .coreDataError(underlying: error)
        }
        
        isUpdating = false
    }
    
    // MARK: - Library Management
    
    func addToLibrary(status: AnimeStatus) async {
        isUpdating = true
        error = nil
        
        do {
            let newUserAnime = try animeService.addAnimeToLibrary(anime, status: status, progress: 0, score: nil)
            self.userAnime = newUserAnime
            self.isInLibrary = true
            
            // Queue the operation for sync
            syncService.queueOperation(.updateProgress(
                mediaId: anime.id,
                progress: 0,
                status: status.rawValue
            ))
            
            // Trigger sync (non-blocking, will be debounced)
            Task.detached(priority: .background) {
                try? await self.syncService.processSyncQueue()
            }
        } catch let kiroError as KiroError {
            error = kiroError
        } catch {
            self.error = .coreDataError(underlying: error)
        }
        
        isUpdating = false
    }
    
    func removeFromLibrary() async {
        guard let userAnime = userAnime else { return }
        
        isUpdating = true
        error = nil
        
        do {
            try animeService.deleteAnimeFromLibrary(userAnime.id)
            
            // Queue the operation for sync
            syncService.queueOperation(.deleteEntry(mediaId: anime.id))
            
            self.userAnime = nil
            self.isInLibrary = false
            
            // Trigger sync (non-blocking, will be debounced)
            Task.detached(priority: .background) {
                try? await self.syncService.processSyncQueue()
            }
        } catch let kiroError as KiroError {
            error = kiroError
        } catch {
            self.error = .coreDataError(underlying: error)
        }
        
        isUpdating = false
    }
    
    // MARK: - External Actions
    
    func openInAniList() {
        guard let url = URL(string: anime.siteUrl) else { return }
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Completion Handling
    
    func handleCompletion(moveToCompleted: Bool) async {
        showCompletionPrompt = false
        
        if moveToCompleted {
            await updateStatus(.completed)
        }
    }
}
