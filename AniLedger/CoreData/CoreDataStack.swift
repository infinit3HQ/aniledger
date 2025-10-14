import Foundation
import CoreData
import Combine

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    static let preview = CoreDataStack(inMemory: true)
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "AniLedger")
        
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable automatic lightweight migration
            let description = persistentContainer.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                // Log the error for debugging
                print("Core Data failed to load: \(error.localizedDescription)")
                
                // In case of migration failure, attempt to recover by deleting the store
                if let storeURL = description.url {
                    self.handleMigrationFailure(storeURL: storeURL)
                } else {
                    fatalError("Failed to load Core Data stack: \(error)")
                }
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save Context
    
    func saveContext() throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Background Context
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Fetch Request Helpers
    
    /// Fetch anime by ID
    func fetchAnime(byId id: Int64, context: NSManagedObjectContext? = nil) -> AnimeEntity? {
        let ctx = context ?? viewContext
        let request = AnimeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %lld", id)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    /// Fetch all anime
    func fetchAllAnime(context: NSManagedObjectContext? = nil) -> [AnimeEntity] {
        let ctx = context ?? viewContext
        let request = AnimeEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "titleRomaji", ascending: true)]
        
        return (try? ctx.fetch(request)) ?? []
    }
    
    /// Fetch user anime by ID
    func fetchUserAnime(byId id: Int64, context: NSManagedObjectContext? = nil) -> UserAnimeEntity? {
        let ctx = context ?? viewContext
        let request = UserAnimeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %lld", id)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    /// Fetch user anime by anime ID
    func fetchUserAnime(byAnimeId animeId: Int64, context: NSManagedObjectContext? = nil) -> UserAnimeEntity? {
        let ctx = context ?? viewContext
        let request = UserAnimeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "animeId == %lld", animeId)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    /// Fetch user anime by status
    func fetchUserAnime(byStatus status: String, context: NSManagedObjectContext? = nil) -> [UserAnimeEntity] {
        let ctx = context ?? viewContext
        let request = UserAnimeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        return (try? ctx.fetch(request)) ?? []
    }
    
    /// Fetch all user anime
    func fetchAllUserAnime(context: NSManagedObjectContext? = nil) -> [UserAnimeEntity] {
        let ctx = context ?? viewContext
        let request = UserAnimeEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "status", ascending: true),
            NSSortDescriptor(key: "sortOrder", ascending: true)
        ]
        
        return (try? ctx.fetch(request)) ?? []
    }
    
    /// Fetch user anime that need sync
    func fetchUserAnimeNeedingSync(context: NSManagedObjectContext? = nil) -> [UserAnimeEntity] {
        let ctx = context ?? viewContext
        let request = UserAnimeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: true)]
        
        return (try? ctx.fetch(request)) ?? []
    }
    
    /// Fetch genre by name
    func fetchGenre(byName name: String, context: NSManagedObjectContext? = nil) -> GenreEntity? {
        let ctx = context ?? viewContext
        let request = GenreEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    /// Fetch or create genre
    func fetchOrCreateGenre(name: String, context: NSManagedObjectContext? = nil) -> GenreEntity {
        let ctx = context ?? viewContext
        
        if let existing = fetchGenre(byName: name, context: ctx) {
            return existing
        }
        
        let genre = GenreEntity(context: ctx)
        genre.name = name
        return genre
    }
    
    /// Fetch all sync queue items
    func fetchSyncQueue(context: NSManagedObjectContext? = nil) -> [SyncQueueEntity] {
        let ctx = context ?? viewContext
        let request = SyncQueueEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        return (try? ctx.fetch(request)) ?? []
    }
    
    /// Fetch sync queue item by ID
    func fetchSyncQueueItem(byId id: UUID, context: NSManagedObjectContext? = nil) -> SyncQueueEntity? {
        let ctx = context ?? viewContext
        let request = SyncQueueEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? ctx.fetch(request).first
    }
    
    // MARK: - Batch Operations
    
    /// Delete all user anime
    func deleteAllUserAnime(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserAnimeEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        try ctx.execute(deleteRequest)
        try saveContext()
    }
    
    /// Delete all anime
    func deleteAllAnime(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AnimeEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        try ctx.execute(deleteRequest)
        try saveContext()
    }
    
    /// Delete all sync queue items
    func deleteAllSyncQueue(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SyncQueueEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        try ctx.execute(deleteRequest)
        try saveContext()
    }
    
    /// Clear all data
    func clearAllData() throws {
        try deleteAllUserAnime()
        try deleteAllAnime()
        try deleteAllSyncQueue()
    }
    
    // MARK: - Migration Support
    
    /// Handle migration failure by deleting the corrupted store and recreating it
    private func handleMigrationFailure(storeURL: URL) {
        print("Attempting to recover from migration failure...")
        
        do {
            // Remove the corrupted store files
            let fileManager = FileManager.default
            
            // Remove main store file
            if fileManager.fileExists(atPath: storeURL.path) {
                try fileManager.removeItem(at: storeURL)
            }
            
            // Remove WAL file
            let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            if fileManager.fileExists(atPath: walURL.path) {
                try fileManager.removeItem(at: walURL)
            }
            
            // Remove SHM file
            let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            if fileManager.fileExists(atPath: shmURL.path) {
                try fileManager.removeItem(at: shmURL)
            }
            
            print("Corrupted store files removed. Recreating store...")
            
            // Reload the persistent store
            persistentContainer.loadPersistentStores { description, error in
                if let error = error {
                    fatalError("Failed to recreate Core Data stack after migration failure: \(error)")
                }
                print("Core Data stack successfully recreated")
            }
        } catch {
            fatalError("Failed to recover from migration failure: \(error)")
        }
    }
    
    /// Check if migration is needed
    func isMigrationNeeded() -> Bool {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            let model = persistentContainer.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            print("Error checking migration status: \(error)")
            return false
        }
    }
    
    /// Get the store file size in bytes
    func getStoreSize() -> Int64? {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            return attributes[.size] as? Int64
        } catch {
            print("Error getting store size: \(error)")
            return nil
        }
    }
    
    /// Destroy and recreate the persistent store (for re-sync scenarios)
    func destroyAndRecreateStore() throws {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            throw KiroError.coreDataError(underlying: NSError(
                domain: "CoreDataStack",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Store URL not found"]
            ))
        }
        
        // Remove all persistent stores
        for store in persistentContainer.persistentStoreCoordinator.persistentStores {
            try persistentContainer.persistentStoreCoordinator.remove(store)
        }
        
        // Delete store files
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }
        
        let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        if fileManager.fileExists(atPath: walURL.path) {
            try fileManager.removeItem(at: walURL)
        }
        
        let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        if fileManager.fileExists(atPath: shmURL.path) {
            try fileManager.removeItem(at: shmURL)
        }
        
        // Recreate the store
        try persistentContainer.persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
        )
        
        print("Persistent store destroyed and recreated successfully")
    }
}
