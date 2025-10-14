//
//  SettingsViewModel.swift
//  AniLedger
//
//  ViewModel for managing app settings and user preferences
//

import Foundation
import Combine

/// Theme preference options
enum ThemePreference: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var user: AniListUser?
    @Published var autoSyncEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: UserDefaultsKeys.autoSyncEnabled)
        }
    }
    @Published var themePreference: ThemePreference = .system {
        didSet {
            UserDefaults.standard.set(themePreference.rawValue, forKey: UserDefaultsKeys.themePreference)
        }
    }
    @Published var isLoggingOut: Bool = false
    @Published var showLogoutConfirmation: Bool = false
    @Published var clearDataOnLogout: Bool = false
    @Published var showClearDataConfirmation: Bool = false
    @Published var isResyncing: Bool = false
    @Published var showResyncConfirmation: Bool = false
    @Published var resyncError: Error?
    @Published var showResyncError: Bool = false
    @Published var resyncSuccess: Bool = false
    
    // MARK: - Dependencies
    
    private let authenticationService: AuthenticationServiceProtocol
    private let coreDataStack: CoreDataStack
    private let syncService: SyncServiceProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults Keys
    
    private enum UserDefaultsKeys {
        static let autoSyncEnabled = "autoSyncEnabled"
        static let themePreference = "themePreference"
    }
    
    // MARK: - Initialization
    
    init(
        authenticationService: AuthenticationServiceProtocol,
        coreDataStack: CoreDataStack = .shared,
        syncService: SyncServiceProtocol? = nil
    ) {
        self.authenticationService = authenticationService
        self.coreDataStack = coreDataStack
        self.syncService = syncService
        
        // Load user profile from authentication service
        self.user = authenticationService.currentUser
        
        // Load saved preferences from UserDefaults
        loadPreferences()
        
        // Observe authentication service for user changes
        observeAuthenticationService()
    }
    
    // MARK: - Load Preferences
    
    /// Load user preferences from UserDefaults
    private func loadPreferences() {
        // Load auto-sync preference (default: true)
        autoSyncEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.autoSyncEnabled) as? Bool ?? true
        
        // Load theme preference (default: system)
        if let themeString = UserDefaults.standard.string(forKey: UserDefaultsKeys.themePreference),
           let theme = ThemePreference(rawValue: themeString) {
            themePreference = theme
        } else {
            themePreference = .system
        }
    }
    
    // MARK: - Observe Authentication Service
    
    /// Observe authentication service for user profile changes
    private func observeAuthenticationService() {
        // If the authentication service is ObservableObject, we can observe it
        // For now, we'll manually update when needed
        if let observableAuth = authenticationService as? AuthenticationService {
            observableAuth.$currentUser
                .receive(on: DispatchQueue.main)
                .assign(to: &$user)
        }
    }
    
    // MARK: - Logout
    
    /// Request logout confirmation
    func requestLogout() {
        showLogoutConfirmation = true
    }
    
    /// Logout user and clear authentication
    func logout() {
        isLoggingOut = true
        
        Task {
            // Clear local data if requested
            if clearDataOnLogout {
                do {
                    try coreDataStack.clearAllData()
                    print("Local data cleared on logout")
                } catch {
                    print("Error clearing local data: \(error)")
                }
            }
            
            // Perform logout on authentication service
            authenticationService.logout()
            
            // Clear user data
            user = nil
            
            isLoggingOut = false
            showLogoutConfirmation = false
            clearDataOnLogout = false
        }
    }
    
    /// Cancel logout request
    func cancelLogout() {
        showLogoutConfirmation = false
    }
    
    // MARK: - Auto-Sync
    
    /// Toggle auto-sync setting
    func toggleAutoSync() {
        autoSyncEnabled.toggle()
        // The didSet observer will persist to UserDefaults
    }
    
    // MARK: - Theme
    
    /// Set theme preference
    /// - Parameter theme: The theme preference to set
    func setTheme(_ theme: ThemePreference) {
        themePreference = theme
        // The didSet observer will persist to UserDefaults
    }
    
    // MARK: - Data Management
    
    /// Request re-sync confirmation
    func requestResync() {
        showResyncConfirmation = true
    }
    
    /// Cancel re-sync request
    func cancelResync() {
        showResyncConfirmation = false
    }
    
    /// Perform full re-sync from AniList
    func performResync() async {
        isResyncing = true
        resyncError = nil
        resyncSuccess = false
        showResyncConfirmation = false
        
        do {
            // Destroy and recreate the persistent store
            try coreDataStack.destroyAndRecreateStore()
            
            // Perform full sync from AniList
            if let syncService = syncService {
                try await syncService.syncAll()
                resyncSuccess = true
            } else {
                throw KiroError.apiError(message: "Sync service not available", statusCode: nil)
            }
        } catch {
            resyncError = error
            showResyncError = true
        }
        
        isResyncing = false
    }
    
    /// Request clear data confirmation
    func requestClearData() {
        showClearDataConfirmation = true
    }
    
    /// Cancel clear data request
    func cancelClearData() {
        showClearDataConfirmation = false
    }
    
    /// Clear all local data
    func clearLocalData() async {
        do {
            try coreDataStack.clearAllData()
            showClearDataConfirmation = false
        } catch {
            resyncError = error
            showResyncError = true
        }
    }
}
