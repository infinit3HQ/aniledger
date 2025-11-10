//
//  SettingsView.swift
//  AniLedger
//
//  Settings view for managing user preferences and account
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // Account Section
            accountSection
            
            // Appearance Section
            appearanceSection
            
            // Sync Section
            syncSection
            
            // Notifications Section
            notificationsSection
            
            // Data Management Section
            dataManagementSection
            
            // Logout Section
            logoutSection
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $viewModel.showNotificationSettings) {
            NotificationSettingsSheet(notificationService: viewModel.notificationService)
                .frame(minWidth: 500, minHeight: 600)
        }
        .alert("Confirm Logout", isPresented: $viewModel.showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelLogout()
            }
            Button("Logout", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            if viewModel.clearDataOnLogout {
                Text("Are you sure you want to logout? All local data will be deleted.")
            } else {
                Text("Are you sure you want to logout? Your local data will be preserved for the next login.")
            }
        }
        .alert("Confirm Re-sync", isPresented: $viewModel.showResyncConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelResync()
            }
            Button("Re-sync", role: .destructive) {
                Task {
                    await viewModel.performResync()
                }
            }
        } message: {
            Text("This will delete all local data and re-download everything from AniList. This action cannot be undone.")
        }
        .alert("Clear Data", isPresented: $viewModel.showClearDataConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelClearData()
            }
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearLocalData()
                }
            }
        } message: {
            Text("This will delete all local anime data. You can re-sync from AniList afterwards.")
        }
        .alert("Error", isPresented: $viewModel.showResyncError) {
            Button("OK", role: .cancel) {
                viewModel.resyncError = nil
            }
        } message: {
            if let error = viewModel.resyncError {
                Text(error.localizedDescription)
            }
        }
        .alert("Success", isPresented: $viewModel.resyncSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Data successfully re-synced from AniList!")
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section {
            if let user = viewModel.user {
                HStack(spacing: 16) {
                    // Avatar
                    if let avatarURL = user.avatar?.medium ?? user.avatar?.large {
                        AsyncImageView(url: avatarURL, width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.accentColor)
                            )
                    }
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                        
                        Text("AniList User")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Not logged in")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Account")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $viewModel.themePreference) {
                ForEach(ThemePreference.allCases, id: \.self) { theme in
                    HStack {
                        Image(systemName: themeIcon(for: theme))
                        Text(theme.rawValue)
                    }
                    .tag(theme)
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose your preferred color scheme. System will follow your macOS appearance settings.")
        }
    }
    
    // MARK: - Sync Section
    
    private var syncSection: some View {
        Section {
            Toggle(isOn: $viewModel.autoSyncEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-Sync")
                        .font(.body)
                    
                    Text("Automatically sync with AniList every 15 minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Synchronization")
        } footer: {
            Text("When enabled, your library will automatically sync with AniList in the background. You can always manually sync from the Library view.")
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            Button {
                viewModel.showNotificationSettings = true
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Airing Notifications")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text("Get notified when new episodes air")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("Notifications")
        }
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        Section {
            // Re-sync button
            Button(action: {
                viewModel.requestResync()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Re-sync from AniList")
                            .font(.body)
                        
                        Text("Delete local data and re-download from AniList")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if viewModel.isResyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(viewModel.isResyncing || viewModel.user == nil)
            
            // Clear local data button
            Button(action: {
                viewModel.requestClearData()
            }) {
                HStack {
                    Image(systemName: "trash")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear Local Data")
                            .font(.body)
                        
                        Text("Remove all cached anime data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .foregroundColor(.orange)
            .disabled(viewModel.user == nil)
        } header: {
            Text("Data Management")
        } footer: {
            Text("Use re-sync if your local data becomes corrupted or out of sync. Clear local data to free up space.")
        }
    }
    
    // MARK: - Logout Section
    
    private var logoutSection: some View {
        Section {
            // Clear data on logout toggle
            Toggle(isOn: $viewModel.clearDataOnLogout) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clear data on logout")
                        .font(.body)
                    
                    Text("Delete all local anime data when logging out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(viewModel.user == nil)
            
            // Logout button
            Button(action: {
                viewModel.requestLogout()
            }) {
                HStack {
                    Spacer()
                    
                    if viewModel.isLoggingOut {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                        
                        Text("Logging out...")
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                    
                    Spacer()
                }
            }
            .foregroundColor(.red)
            .disabled(viewModel.isLoggingOut || viewModel.user == nil)
        } footer: {
            Text("If clear data on logout is disabled, your anime library will be preserved for the next login.")
        }
    }
    
    // MARK: - Helper Functions
    
    private func themeIcon(for theme: ThemePreference) -> String {
        switch theme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(
            authenticationService: MockAuthenticationService(),
            coreDataStack: .preview,
            syncService: nil
        ))
    }
}

// MARK: - Mock Authentication Service

private class MockAuthenticationService: AuthenticationServiceProtocol {
    var isAuthenticated: Bool = true
    
    var currentUser: AniListUser? = AniListUser(
        id: 12345,
        name: "TestUser",
        avatar: UserAvatar(
            large: "https://s4.anilist.co/file/anilistcdn/user/avatar/large/default.png",
            medium: "https://s4.anilist.co/file/anilistcdn/user/avatar/medium/default.png"
        )
    )
    
    func authenticate() async throws -> AuthToken {
        AuthToken(accessToken: "mock_token", tokenType: "Bearer", expiresIn: 3600)
    }
    
    func logout() {
        // No-op for preview
    }
    
    func refreshToken() async throws -> AuthToken {
        AuthToken(accessToken: "mock_token", tokenType: "Bearer", expiresIn: 3600)
    }
}
