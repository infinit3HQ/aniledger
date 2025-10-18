//
//  AnimeService.swift
//  AniLedger
//
//  Service for managing anime library operations with Core Data
//

import Foundation
import CoreData

protocol AnimeServiceProtocol {
    func addAnimeToLibrary(_ anime: Anime, status: AnimeStatus, progress: Int, score: Double?) throws -> UserAnime
    func updateAnimeProgress(_ userAnimeId: Int, progress: Int) throws -> UserAnime
    func updateAnimeStatus(_ userAnimeId: Int, status: AnimeStatus) throws -> UserAnime
    func updateAnimeScore(_ userAnimeId: Int, score: Double?) throws -> UserAnime
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime]
    func fetchAllUserAnime() throws -> [UserAnime]
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws
    func getUserAnime(byId id: Int) throws -> UserAnime?
    func getUserAnime(byAnimeId animeId: Int) throws -> UserAnime?
}

class AnimeService: AnimeServiceProtocol {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Add Anime to Library
    
    func addAnimeToLibrary(_ anime: Anime, status: AnimeStatus, progress: Int = 0, score: Double? = nil) throws -> UserAnime {
        let context = coreDataStack.viewContext
        
        // Check if anime already exists in library
        if coreDataStack.fetchUserAnime(byAnimeId: Int64(anime.id), context: context) != nil {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Anime already exists in library"]
            ))
        }
        
        // Fetch or create AnimeEntity
        let animeEntity = try fetchOrCreateAnimeEntity(from: anime, context: context)
        
        // Get next sort order for the status
        let nextSortOrder = getNextSortOrder(for: status, context: context)
        
        // Create UserAnimeEntity
        let userAnimeEntity = UserAnimeEntity(context: context)
        userAnimeEntity.id = Int64(anime.id) // Use anime ID as user anime ID
        userAnimeEntity.animeId = Int64(anime.id)
        userAnimeEntity.status = status.rawValue
        userAnimeEntity.progress = Int32(progress)
        userAnimeEntity.score = score ?? 0.0
        userAnimeEntity.sortOrder = Int32(nextSortOrder)
        userAnimeEntity.needsSync = true
        userAnimeEntity.lastModified = Date()
        userAnimeEntity.anime = animeEntity
        
        try coreDataStack.saveContext()
        
        return try convertToUserAnime(userAnimeEntity)
    }
    
    // MARK: - Update Anime
    
    func updateAnimeProgress(_ userAnimeId: Int, progress: Int) throws -> UserAnime {
        let context = coreDataStack.viewContext
        
        guard let userAnimeEntity = coreDataStack.fetchUserAnime(byId: Int64(userAnimeId), context: context) else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "User anime not found"]
            ))
        }
        
        userAnimeEntity.progress = Int32(progress)
        userAnimeEntity.needsSync = true
        userAnimeEntity.lastModified = Date()
        
        try coreDataStack.saveContext()
        
        return try convertToUserAnime(userAnimeEntity)
    }
    
    func updateAnimeStatus(_ userAnimeId: Int, status: AnimeStatus) throws -> UserAnime {
        let context = coreDataStack.viewContext
        
        guard let userAnimeEntity = coreDataStack.fetchUserAnime(byId: Int64(userAnimeId), context: context) else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "User anime not found"]
            ))
        }
        
        userAnimeEntity.status = status.rawValue
        userAnimeEntity.needsSync = true
        userAnimeEntity.lastModified = Date()
        
        try coreDataStack.saveContext()
        
        return try convertToUserAnime(userAnimeEntity)
    }
    
    func updateAnimeScore(_ userAnimeId: Int, score: Double?) throws -> UserAnime {
        let context = coreDataStack.viewContext
        
        guard let userAnimeEntity = coreDataStack.fetchUserAnime(byId: Int64(userAnimeId), context: context) else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "User anime not found"]
            ))
        }
        
        userAnimeEntity.score = score ?? 0.0
        userAnimeEntity.needsSync = true
        userAnimeEntity.lastModified = Date()
        
        try coreDataStack.saveContext()
        
        return try convertToUserAnime(userAnimeEntity)
    }
    
    // MARK: - Delete Anime
    
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws {
        let context = coreDataStack.viewContext
        
        guard let userAnimeEntity = coreDataStack.fetchUserAnime(byId: Int64(userAnimeId), context: context) else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "User anime not found"]
            ))
        }
        
        context.delete(userAnimeEntity)
        try coreDataStack.saveContext()
    }
    
    // MARK: - Fetch Anime
    
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime] {
        let context = coreDataStack.viewContext
        let entities = coreDataStack.fetchUserAnime(byStatus: status.rawValue, context: context)
        
        return try entities.map { try convertToUserAnime($0) }
    }
    
    func fetchAllUserAnime() throws -> [UserAnime] {
        let context = coreDataStack.viewContext
        let entities = coreDataStack.fetchAllUserAnime(context: context)
        
        return try entities.map { try convertToUserAnime($0) }
    }
    
    func getUserAnime(byId id: Int) throws -> UserAnime? {
        let context = coreDataStack.viewContext
        
        guard let entity = coreDataStack.fetchUserAnime(byId: Int64(id), context: context) else {
            return nil
        }
        
        return try convertToUserAnime(entity)
    }
    
    func getUserAnime(byAnimeId animeId: Int) throws -> UserAnime? {
        let context = coreDataStack.viewContext
        
        guard let entity = coreDataStack.fetchUserAnime(byAnimeId: Int64(animeId), context: context) else {
            return nil
        }
        
        return try convertToUserAnime(entity)
    }
    
    // MARK: - Move Between Lists
    
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime {
        let context = coreDataStack.viewContext
        
        guard let userAnimeEntity = coreDataStack.fetchUserAnime(byId: Int64(userAnimeId), context: context) else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "User anime not found"]
            ))
        }
        
        let oldStatus = userAnimeEntity.status
        
        // Update status
        userAnimeEntity.status = toStatus.rawValue
        
        // Get next sort order for the new status
        let nextSortOrder = getNextSortOrder(for: toStatus, context: context)
        userAnimeEntity.sortOrder = Int32(nextSortOrder)
        
        userAnimeEntity.needsSync = true
        userAnimeEntity.lastModified = Date()
        
        try coreDataStack.saveContext()
        
        // Reorder remaining items in old status
        if let oldStatusEnum = AnimeStatus(rawValue: oldStatus ?? "") {
            try reorderAfterRemoval(in: oldStatusEnum, context: context)
        }
        
        return try convertToUserAnime(userAnimeEntity)
    }
    
    // MARK: - Reorder Anime
    
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws {
        let context = coreDataStack.viewContext
        
        // Fetch all anime for the status
        let entities = coreDataStack.fetchUserAnime(byStatus: status.rawValue, context: context)
        
        guard sourceIndex >= 0 && sourceIndex < entities.count else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Invalid source index"]
            ))
        }
        
        guard destinationIndex >= 0 && destinationIndex < entities.count else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "Invalid destination index"]
            ))
        }
        
        // Create mutable array
        var mutableEntities = entities
        
        // Move the item
        let movedItem = mutableEntities.remove(at: sourceIndex)
        mutableEntities.insert(movedItem, at: destinationIndex)
        
        // Update sort orders
        for (index, entity) in mutableEntities.enumerated() {
            entity.sortOrder = Int32(index)
            entity.needsSync = true
            entity.lastModified = Date()
        }
        
        try coreDataStack.saveContext()
    }
    
    // MARK: - Helper Methods
    
    private func fetchOrCreateAnimeEntity(from anime: Anime, context: NSManagedObjectContext) throws -> AnimeEntity {
        // Try to fetch existing anime
        if let existing = coreDataStack.fetchAnime(byId: Int64(anime.id), context: context) {
            // Update existing anime data
            existing.titleRomaji = anime.title.romaji
            existing.titleEnglish = anime.title.english
            existing.titleNative = anime.title.native
            existing.coverImageLarge = anime.coverImage.large
            existing.coverImageMedium = anime.coverImage.medium
            existing.episodes = Int32(anime.episodes ?? 0)
            existing.format = anime.format.rawValue
            existing.synopsis = anime.synopsis
            existing.siteUrl = anime.siteUrl
            existing.lastSynced = Date()
            
            // Update genres
            existing.genres = NSSet(array: anime.genres.map { genreName in
                coreDataStack.fetchOrCreateGenre(name: genreName, context: context)
            })
            
            return existing
        }
        
        // Create new anime entity
        let animeEntity = AnimeEntity(context: context)
        animeEntity.id = Int64(anime.id)
        animeEntity.titleRomaji = anime.title.romaji
        animeEntity.titleEnglish = anime.title.english
        animeEntity.titleNative = anime.title.native
        animeEntity.coverImageLarge = anime.coverImage.large
        animeEntity.coverImageMedium = anime.coverImage.medium
        animeEntity.episodes = Int32(anime.episodes ?? 0)
        animeEntity.format = anime.format.rawValue
        animeEntity.synopsis = anime.synopsis
        animeEntity.siteUrl = anime.siteUrl
        animeEntity.lastSynced = Date()
        
        // Add genres
        animeEntity.genres = NSSet(array: anime.genres.map { genreName in
            coreDataStack.fetchOrCreateGenre(name: genreName, context: context)
        })
        
        return animeEntity
    }
    
    private func convertToUserAnime(_ entity: UserAnimeEntity) throws -> UserAnime {
        guard let animeEntity = entity.anime else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1005,
                userInfo: [NSLocalizedDescriptionKey: "Anime entity not found for user anime"]
            ))
        }
        
        let anime = try convertToAnime(animeEntity)
        
        guard let status = AnimeStatus(rawValue: entity.status ?? "") else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1006,
                userInfo: [NSLocalizedDescriptionKey: "Invalid anime status"]
            ))
        }
        
        return UserAnime(
            id: Int(entity.id),
            anime: anime,
            status: status,
            progress: Int(entity.progress),
            score: entity.score > 0 ? entity.score : nil,
            sortOrder: Int(entity.sortOrder),
            needsSync: entity.needsSync,
            lastModified: entity.lastModified ?? Date()
        )
    }
    
    private func convertToAnime(_ entity: AnimeEntity) throws -> Anime {
        let title = AnimeTitle(
            romaji: entity.titleRomaji ?? "",
            english: entity.titleEnglish,
            native: entity.titleNative
        )
        
        let coverImage = CoverImage(
            large: entity.coverImageLarge ?? "",
            medium: entity.coverImageMedium ?? ""
        )
        
        guard let format = AnimeFormat(rawValue: entity.format ?? "") else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "AnimeService",
                code: 1007,
                userInfo: [NSLocalizedDescriptionKey: "Invalid anime format"]
            ))
        }
        
        let genres = (entity.genres?.allObjects as? [GenreEntity])?.compactMap { $0.name } ?? []
        
        return Anime(
            id: Int(entity.id),
            title: title,
            coverImage: coverImage,
            episodes: entity.episodes > 0 ? Int(entity.episodes) : nil,
            format: format,
            genres: genres,
            synopsis: entity.synopsis,
            siteUrl: entity.siteUrl ?? ""
        )
    }
    
    private func getNextSortOrder(for status: AnimeStatus, context: NSManagedObjectContext) -> Int {
        let entities = coreDataStack.fetchUserAnime(byStatus: status.rawValue, context: context)
        
        if entities.isEmpty {
            return 0
        }
        
        let maxSortOrder = entities.map { Int($0.sortOrder) }.max() ?? -1
        return maxSortOrder + 1
    }
    
    private func reorderAfterRemoval(in status: AnimeStatus, context: NSManagedObjectContext) throws {
        let entities = coreDataStack.fetchUserAnime(byStatus: status.rawValue, context: context)
        
        // Update sort orders to be sequential
        for (index, entity) in entities.enumerated() {
            entity.sortOrder = Int32(index)
        }
        
        try coreDataStack.saveContext()
    }
}
