//
//  MockAnimeService.swift
//  AniLedgerTests
//
//  Mock implementation of AnimeServiceProtocol for testing
//

import Foundation
@testable import AniLedger

class MockAnimeService: AnimeServiceProtocol {
    var addAnimeCallCount = 0
    var updateProgressCallCount = 0
    var updateStatusCallCount = 0
    var updateScoreCallCount = 0
    var deleteAnimeCallCount = 0
    var fetchAnimeByStatusCallCount = 0
    var fetchAllUserAnimeCallCount = 0
    var moveAnimeBetweenListsCallCount = 0
    var reorderAnimeCallCount = 0
    var getUserAnimeByIdCallCount = 0
    var getUserAnimeByAnimeIdCallCount = 0
    
    var lastDeletedAnimeId: Int?
    var lastMovedAnimeId: Int?
    var lastMovedToStatus: AnimeStatus?
    var lastReorderStatus: AnimeStatus?
    var lastReorderSourceIndex: Int?
    var lastReorderDestinationIndex: Int?
    
    var animeByStatus: [AnimeStatus: [UserAnime]] = [:]
    var allUserAnime: [UserAnime] = []
    var moveAnimeBetweenListsResult: UserAnime?
    var shouldThrowError: Error?
    
    func addAnimeToLibrary(_ anime: Anime, status: AnimeStatus, progress: Int, score: Double?) throws -> UserAnime {
        addAnimeCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        return UserAnime(
            id: anime.id,
            anime: anime,
            status: status,
            progress: progress,
            score: score,
            sortOrder: 0,
            needsSync: true,
            lastModified: Date()
        )
    }
    
    func updateAnimeProgress(_ userAnimeId: Int, progress: Int) throws -> UserAnime {
        updateProgressCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        // Find and update the anime
        for (status, animeList) in animeByStatus {
            if let anime = animeList.first(where: { $0.id == userAnimeId }) {
                return UserAnime(
                    id: anime.id,
                    anime: anime.anime,
                    status: status,
                    progress: progress,
                    score: anime.score,
                    sortOrder: anime.sortOrder,
                    needsSync: true,
                    lastModified: Date()
                )
            }
        }
        
        throw KiroError.coreDataError(underlying: NSError(domain: "Mock", code: 1, userInfo: nil))
    }
    
    func updateAnimeStatus(_ userAnimeId: Int, status: AnimeStatus) throws -> UserAnime {
        updateStatusCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        for (_, animeList) in animeByStatus {
            if let anime = animeList.first(where: { $0.id == userAnimeId }) {
                return UserAnime(
                    id: anime.id,
                    anime: anime.anime,
                    status: status,
                    progress: anime.progress,
                    score: anime.score,
                    sortOrder: anime.sortOrder,
                    needsSync: true,
                    lastModified: Date()
                )
            }
        }
        
        throw KiroError.coreDataError(underlying: NSError(domain: "Mock", code: 1, userInfo: nil))
    }
    
    func updateAnimeScore(_ userAnimeId: Int, score: Double?) throws -> UserAnime {
        updateScoreCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        for (status, animeList) in animeByStatus {
            if let anime = animeList.first(where: { $0.id == userAnimeId }) {
                return UserAnime(
                    id: anime.id,
                    anime: anime.anime,
                    status: status,
                    progress: anime.progress,
                    score: score,
                    sortOrder: anime.sortOrder,
                    needsSync: true,
                    lastModified: Date()
                )
            }
        }
        
        throw KiroError.coreDataError(underlying: NSError(domain: "Mock", code: 1, userInfo: nil))
    }
    
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws {
        deleteAnimeCallCount += 1
        lastDeletedAnimeId = userAnimeId
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime] {
        fetchAnimeByStatusCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        return animeByStatus[status] ?? []
    }
    
    func fetchAllUserAnime() throws -> [UserAnime] {
        fetchAllUserAnimeCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        return allUserAnime
    }
    
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime {
        moveAnimeBetweenListsCallCount += 1
        lastMovedAnimeId = userAnimeId
        lastMovedToStatus = toStatus
        
        if let error = shouldThrowError {
            throw error
        }
        
        if let result = moveAnimeBetweenListsResult {
            return result
        }
        
        throw KiroError.coreDataError(underlying: NSError(domain: "Mock", code: 1, userInfo: nil))
    }
    
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws {
        reorderAnimeCallCount += 1
        lastReorderStatus = status
        lastReorderSourceIndex = sourceIndex
        lastReorderDestinationIndex = destinationIndex
        
        if let error = shouldThrowError {
            throw error
        }
    }
    
    func getUserAnime(byId id: Int) throws -> UserAnime? {
        getUserAnimeByIdCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        for (_, animeList) in animeByStatus {
            if let anime = animeList.first(where: { $0.id == id }) {
                return anime
            }
        }
        
        return nil
    }
    
    func getUserAnime(byAnimeId animeId: Int) throws -> UserAnime? {
        getUserAnimeByAnimeIdCallCount += 1
        
        if let error = shouldThrowError {
            throw error
        }
        
        for (_, animeList) in animeByStatus {
            if let anime = animeList.first(where: { $0.anime.id == animeId }) {
                return anime
            }
        }
        
        return nil
    }
    
    func reset() {
        addAnimeCallCount = 0
        updateProgressCallCount = 0
        updateStatusCallCount = 0
        updateScoreCallCount = 0
        deleteAnimeCallCount = 0
        fetchAnimeByStatusCallCount = 0
        fetchAllUserAnimeCallCount = 0
        moveAnimeBetweenListsCallCount = 0
        reorderAnimeCallCount = 0
        getUserAnimeByIdCallCount = 0
        getUserAnimeByAnimeIdCallCount = 0
        
        lastDeletedAnimeId = nil
        lastMovedAnimeId = nil
        lastMovedToStatus = nil
        lastReorderStatus = nil
        lastReorderSourceIndex = nil
        lastReorderDestinationIndex = nil
        
        animeByStatus = [:]
        allUserAnime = []
        moveAnimeBetweenListsResult = nil
        shouldThrowError = nil
    }
}
