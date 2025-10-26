//
//  AniLedgerApp.swift
//  AniLedger
//
//  Created by Niraj Dilshan on 2025-10-13.
//

import SwiftUI

@main
struct AniLedgerApp: App {
    // MARK: - State Objects
    
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var authenticationService: AuthenticationService
    
    // MARK: - Dependencies
    
    private let keychainManager: KeychainManagerProtocol
    private let apiClient: AniListAPIClientProtocol
    private let syncService: SyncServiceProtocol
    
    // MARK: - App Storage
    
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled: Bool = true
    
    // MARK: - Initialization
    
    init() {
        // Configure image cache
        ImageCacheManager.shared.configureCache()
        
        // Initialize dependencies
        let keychainManager = KeychainManager()
        let apiClient = AniListAPIClient(session: .shared) {
            try? keychainManager.retrieve(for: Config.keychainAccessTokenKey)
        }
        
        // Initialize authentication service
        let authService = AuthenticationService(
            keychainManager: keychainManager,
            apiClient: apiClient
        )
        
        // Initialize sync service
        let animeService = AnimeService(coreDataStack: .shared)
        let syncService = SyncService(
            apiClient: apiClient,
            coreDataStack: .shared,
            animeService: animeService,
            userIdProvider: { authService.currentUser?.id }
        )
        
        // Store dependencies
        self.keychainManager = keychainManager
        self.apiClient = apiClient
        self.syncService = syncService
        
        // Set state objects
        _authenticationService = StateObject(wrappedValue: authService)
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                authenticationService: authenticationService,
                coreDataStack: coreDataStack,
                keychainManager: keychainManager,
                apiClient: apiClient
            )
            .environment(\.managedObjectContext, coreDataStack.viewContext)
            .environmentObject(coreDataStack)
            .environmentObject(authenticationService)
            .onAppear {
                performAutoSyncIfEnabled()
            }
            .onChange(of: authenticationService.isAuthenticated) { _, isAuthenticated in
                // Trigger auto-sync when user becomes authenticated
                if isAuthenticated && authenticationService.currentUser != nil {
                    performAutoSyncIfEnabled()
                }
            }
        }
    }
    
    // MARK: - Auto-Sync
    
    /// Perform auto-sync on app launch if enabled and user is authenticated
    private func performAutoSyncIfEnabled() {
        print("🔄 performAutoSyncIfEnabled called")
        print("   - autoSyncEnabled: \(autoSyncEnabled)")
        print("   - isAuthenticated: \(authenticationService.isAuthenticated)")
        print("   - currentUser: \(authenticationService.currentUser?.name ?? "nil")")
        
        guard autoSyncEnabled && authenticationService.isAuthenticated else {
            print("⏭️  Skipping auto-sync (not enabled or not authenticated)")
            return
        }
        
        print("✅ Starting auto-sync...")
        
        Task {
            do {
                // Process any pending sync queue items first
                print("🔄 Processing sync queue...")
                try await syncService.processSyncQueue()
                
                // Then perform incremental sync
                print("🔄 Syncing user lists...")
                try await syncService.syncUserLists()
                
                print("✅ Auto-sync completed successfully")
            } catch {
                // Log error but don't block app launch
                print("❌ Auto-sync failed: \(error.localizedDescription)")
            }
        }
    }
}
