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
    private let airingScheduleService: AiringScheduleServiceProtocol
    private let notificationService: NotificationServiceProtocol
    
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
        
        // Initialize notification service
        let notificationService = NotificationService()
        
        // Initialize anime service and wire up notification service
        let animeService = AnimeService(coreDataStack: .shared)
        animeService.setNotificationService(notificationService)
        
        // Initialize sync service
        let syncService = SyncService(
            apiClient: apiClient,
            coreDataStack: .shared,
            animeService: animeService,
            userIdProvider: { authService.currentUser?.id }
        )
        
        // Initialize airing schedule service
        let airingScheduleService = AiringScheduleService(
            animeService: animeService,
            notificationService: notificationService,
            apiClient: apiClient
        )
        
        // Store dependencies
        self.keychainManager = keychainManager
        self.apiClient = apiClient
        self.syncService = syncService
        self.notificationService = notificationService
        self.airingScheduleService = airingScheduleService
        
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
                apiClient: apiClient,
                notificationService: notificationService
            )
            .environment(\.managedObjectContext, coreDataStack.viewContext)
            .environmentObject(coreDataStack)
            .environmentObject(authenticationService)
            .onAppear {
                performAutoSyncIfEnabled()
                setupNotifications()
            }
            .onChange(of: authenticationService.isAuthenticated) { _, isAuthenticated in
                // Trigger auto-sync when user becomes authenticated
                if isAuthenticated && authenticationService.currentUser != nil {
                    performAutoSyncIfEnabled()
                    startAiringMonitoring()
                } else {
                    airingScheduleService.stopMonitoring()
                    notificationService.cancelAllNotifications()
                }
            }
        }
    }
    
    // MARK: - Auto-Sync
    
    /// Perform auto-sync on app launch if enabled and user is authenticated
    private func performAutoSyncIfEnabled() {
        guard autoSyncEnabled && authenticationService.isAuthenticated else {
            return
        }
        
        Task {
            do {
                // Process any pending sync queue items first
                try await syncService.processSyncQueue()
                
                // Then perform incremental sync
                try await syncService.syncUserLists()
            } catch {
                // Silently fail - don't block app launch
            }
        }
    }
    
    // MARK: - Notifications
    
    /// Request notification permissions and setup
    private func setupNotifications() {
        Task {
            let granted = await notificationService.requestAuthorization()
            if granted && authenticationService.isAuthenticated {
                startAiringMonitoring()
            }
        }
    }
    
    /// Start monitoring airing schedules
    private func startAiringMonitoring() {
        airingScheduleService.startMonitoring()
    }
}
