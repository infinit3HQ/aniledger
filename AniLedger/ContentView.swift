//
//  ContentView.swift
//  AniLedger
//
//  Main content view with navigation split view
//

import SwiftUI

struct ContentView: View {
    // MARK: - Dependencies
    
    @ObservedObject var authenticationService: AuthenticationService
    let coreDataStack: CoreDataStack
    let keychainManager: KeychainManagerProtocol
    let apiClient: AniListAPIClientProtocol
    let animeService: AnimeServiceProtocol
    let syncService: SyncServiceProtocol
    let notificationService: NotificationServiceProtocol
    
    // MARK: - Retained ViewModels
    
    @StateObject private var libraryViewModel: LibraryViewModel
    @StateObject private var discoverViewModel: DiscoverViewModel
    @StateObject private var seasonsViewModel: SeasonsViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    // MARK: - Navigation State
    
    @State private var selectedNavigation: NavigationItem? = .library
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // MARK: - Theme State
    
    @AppStorage("themePreference") private var themePreference: String = ThemePreference.system.rawValue
    
    // MARK: - Initialization
    
    init(
        authenticationService: AuthenticationService,
        coreDataStack: CoreDataStack,
        keychainManager: KeychainManagerProtocol,
        apiClient: AniListAPIClientProtocol,
        animeService: AnimeServiceProtocol? = nil,
        syncService: SyncServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol
    ) {
        self.authenticationService = authenticationService
        self.coreDataStack = coreDataStack
        self.keychainManager = keychainManager
        self.apiClient = apiClient
        self.notificationService = notificationService
        
        let resolvedAnimeService = animeService ?? AnimeService(coreDataStack: coreDataStack)
        let resolvedSyncService = syncService ?? SyncService(
            apiClient: apiClient,
            coreDataStack: coreDataStack,
            animeService: resolvedAnimeService,
            userIdProvider: { [weak authenticationService] in
                authenticationService?.currentUser?.id
            },
            userLoader: { [weak authenticationService] in
                try await authenticationService?.loadUserProfileIfNeeded()
            }
        )
        
        self.animeService = resolvedAnimeService
        self.syncService = resolvedSyncService
        
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(
            animeService: resolvedAnimeService,
            syncService: resolvedSyncService
        ))
        
        _discoverViewModel = StateObject(wrappedValue: DiscoverViewModel(
            apiClient: apiClient,
            animeService: resolvedAnimeService,
            syncService: resolvedSyncService
        ))
        
        _seasonsViewModel = StateObject(wrappedValue: SeasonsViewModel(
            apiClient: apiClient
        ))
        
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(
            apiClient: apiClient,
            animeService: resolvedAnimeService,
            syncService: resolvedSyncService
        ))
        
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(
            authenticationService: authenticationService,
            coreDataStack: coreDataStack,
            syncService: resolvedSyncService,
            notificationService: notificationService
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authenticationService.isAuthenticated {
                mainNavigationView
            } else {
                LoginView(authenticationService: authenticationService)
            }
        }
        .preferredColorScheme(colorScheme)
        .sheet(item: $deepLinkAnime) { anime in
            AnimeDetailView(viewModel: AnimeDetailViewModel(
                anime: anime.anime,
                userAnime: anime,
                animeService: animeService,
                syncService: syncService
            ))
            .frame(minWidth: 600, idealWidth: 600, maxWidth: 600,
                   minHeight: 700, idealHeight: 700, maxHeight: 700)
        }
        .onReceive(notificationService.deepLinkPublisher) { animeId in
            handleDeepLink(animeId: animeId)
        }
    }
    
    // MARK: - Main Navigation View
    
    private var mainNavigationView: some View {
        VStack(spacing: 0) {
            // Offline indicator
            OfflineIndicatorView()
                .animation(.easeInOut, value: NetworkMonitor.shared.isConnected)
            
            // Main navigation
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Sidebar
                sidebar
            } detail: {
                // Detail pane
                detailView
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedNavigation) {
            Section {
                NavigationLink(value: NavigationItem.library) {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                
                NavigationLink(value: NavigationItem.discover) {
                    Label("Discover", systemImage: "sparkles")
                }
                
                NavigationLink(value: NavigationItem.seasons) {
                    Label("Seasons", systemImage: "calendar")
                }
                
                NavigationLink(value: NavigationItem.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
            
            Section {
                NavigationLink(value: NavigationItem.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .navigationTitle("AniLedger")
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedNavigation {
        case .library:
            LibraryView(
                viewModel: libraryViewModel,
                animeService: animeService,
                syncService: syncService
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .discover:
            DiscoverView(
                viewModel: discoverViewModel,
                animeService: animeService,
                syncService: syncService
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .seasons:
            SeasonsView(
                viewModel: seasonsViewModel,
                animeService: animeService,
                syncService: syncService
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .search:
            SearchView(
                viewModel: searchViewModel,
                animeService: animeService,
                syncService: syncService
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .settings:
            SettingsView(viewModel: settingsViewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            
        case .none:
            // Default view when nothing is selected
            EmptyStateView(
                icon: "books.vertical.fill",
                title: "Welcome to AniLedger",
                message: "Select an option from the sidebar to get started"
            )
            .transition(.opacity)
        }
    }
    
    // MARK: - Color Scheme
    
    private var colorScheme: ColorScheme? {
        guard let theme = ThemePreference(rawValue: themePreference) else {
            return nil
        }
        
        switch theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    // MARK: - Deep Link Handling
    
    @State private var deepLinkAnime: UserAnime?
    
    private func handleDeepLink(animeId: Int) {
        do {
            if let anime = try animeService.getUserAnime(byAnimeId: animeId) {
                deepLinkAnime = anime
            }
        } catch {
            print("Failed to fetch anime for deep link: \(error)")
        }
    }
}

// MARK: - Navigation Item

enum NavigationItem: Hashable {
    case library
    case discover
    case seasons
    case search
    case settings
}

// MARK: - Preview

#Preview("Authenticated") {
    let keychainManager = MockKeychainManager()
    let apiClient = MockAniListAPIClient()
    let authService = AuthenticationService(
        keychainManager: keychainManager,
        apiClient: apiClient
    )
    
    // Simulate authenticated state
    try? keychainManager.save(token: "mock_token", for: "anilist_access_token")
    
    return ContentView(
        authenticationService: authService,
        coreDataStack: CoreDataStack.preview,
        keychainManager: keychainManager,
        apiClient: apiClient,
        notificationService: NotificationService()
    )
}

#Preview("Not Authenticated") {
    let keychainManager = MockKeychainManager()
    let apiClient = MockAniListAPIClient()
    let authService = AuthenticationService(
        keychainManager: keychainManager,
        apiClient: apiClient
    )
    
    return ContentView(
        authenticationService: authService,
        coreDataStack: CoreDataStack.preview,
        keychainManager: keychainManager,
        apiClient: apiClient,
        notificationService: NotificationService()
    )
}

// MARK: - Mock Services for Preview

private class MockKeychainManager: KeychainManagerProtocol {
    private var storage: [String: String] = [:]
    
    func save(token: String, for key: String) throws {
        storage[key] = token
    }
    
    func retrieve(for key: String) throws -> String? {
        storage[key]
    }
    
    func delete(for key: String) throws {
        storage.removeValue(forKey: key)
    }
}

private class MockAniListAPIClient: AniListAPIClientProtocol {
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T {
        throw KiroError.invalidResponse
    }
    
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T {
        throw KiroError.invalidResponse
    }
}
