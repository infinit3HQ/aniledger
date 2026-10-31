//
//  AuthenticationService.swift
//  AniLedger
//
//  Created by Niraj Dilshan on 10/13/2025.
//

import Foundation
import Combine
import AuthenticationServices

/// Protocol defining authentication operations
protocol AuthenticationServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: AniListUser? { get }
    
    func authenticate() async throws -> AuthToken
    func logout()
    func refreshToken() async throws -> AuthToken
}

/// Service class for handling AniList OAuth2 authentication
class AuthenticationService: NSObject, AuthenticationServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: AniListUser?
    
    private let keychainManager: KeychainManagerProtocol
    private let apiClient: AniListAPIClientProtocol
    
    // OAuth Configuration - using Config constants
    private var clientId: String { Config.aniListClientId }
    private let authorizationEndpoint = Config.authorizationUrl
    
    // Keychain keys - using Config constants
    private let accessTokenKey = Config.keychainAccessTokenKey
    private var sessionExpiredObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init(keychainManager: KeychainManagerProtocol, apiClient: AniListAPIClientProtocol) {
        self.keychainManager = keychainManager
        self.apiClient = apiClient
        super.init()
        
        observeSessionExpiry()
        
        // Check if user is already authenticated
        checkAuthenticationState()
    }
    
    // MARK: - Authentication State
    
    /// Check if user has a valid token stored.
    ///
    /// If AniList rejects the stored token (expired or revoked), the token is
    /// cleared so the user is sent back to the login screen. If the profile
    /// fetch fails for other reasons (e.g. offline), the user stays signed in
    /// and the profile is loaded later via `loadUserProfileIfNeeded()`.
    private func checkAuthenticationState() {
        let storedToken: String?
        do {
            storedToken = try keychainManager.retrieve(for: accessTokenKey)
        } catch {
            isAuthenticated = false
            return
        }

        guard let token = storedToken, !token.isEmpty else { return }

        Task {
            do {
                try await fetchUserProfile()
                await MainActor.run { isAuthenticated = true }
            } catch let error as KiroError where Self.isInvalidTokenError(error) {
                await MainActor.run { self.logout() }
            } catch {
                await MainActor.run { isAuthenticated = true }
            }
        }
    }

    /// Loads the user profile if it hasn't been loaded yet (e.g. the app
    /// launched offline). Logs the user out if AniList rejects the token.
    func loadUserProfileIfNeeded() async throws {
        guard isAuthenticated, currentUser == nil else { return }

        do {
            try await fetchUserProfile()
        } catch let error as KiroError where Self.isInvalidTokenError(error) {
            await MainActor.run { self.logout() }
            throw error
        }
    }

    /// Signs the user out when any API call reports the token is no longer
    /// valid. At launch (not yet authenticated) checkAuthenticationState()
    /// handles it instead.
    private func observeSessionExpiry() {
        sessionExpiredObserver = NotificationCenter.default.addObserver(
            forName: .aniListSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, self.isAuthenticated else { return }
                self.logout()
            }
        }
    }

    /// True when the error means AniList rejected the access token.
    static func isInvalidTokenError(_ error: KiroError) -> Bool {
        if case .authenticationFailed(let reason) = error {
            return reason == KiroError.invalidTokenReason
        }
        return false
    }
    
    // MARK: - Authentication
    
    /// Initiate OAuth2 authentication flow
    /// - Returns: AuthToken containing access token and metadata
    /// - Throws: KiroError if authentication fails
    func authenticate() async throws -> AuthToken {
        guard Config.isClientIdConfigured else {
            throw KiroError.authenticationFailed(
                reason: "AniList Client ID is not configured. Set ANILIST_CLIENT_ID and rebuild the app."
            )
        }

        // Generate authorization URL
        guard let authURL = generateAuthorizationURL() else {
            throw KiroError.authenticationFailed(reason: "Failed to generate authorization URL")
        }
        
        // Present authentication session. With the implicit grant, AniList
        // returns the access token directly in the redirect URL fragment.
        let token = try await presentAuthenticationSession(url: authURL)
        
        // Store token in keychain
        try keychainManager.save(token: token.accessToken, for: accessTokenKey)
        
        // Fetch user profile BEFORE setting isAuthenticated
        // This ensures currentUser is populated before any auto-sync attempts
        try await fetchUserProfile()
        
        // Update authentication state
        await MainActor.run {
            isAuthenticated = true
        }
        
        return token
    }
    
    /// Generate OAuth2 implicit-grant authorization URL.
    /// AniList redirects to the redirect URI registered for the client.
    /// - Returns: URL for authorization or nil if invalid
    private func generateAuthorizationURL() -> URL? {
        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "token")
        ]
        
        return components?.url
    }
    
    /// Present ASWebAuthenticationSession for OAuth flow
    /// - Parameter url: Authorization URL
    /// - Returns: Access token parsed from the callback URL
    /// - Throws: KiroError if authentication fails or is cancelled
    private func presentAuthenticationSession(url: URL) async throws -> AuthToken {
        return try await withCheckedThrowingContinuation { continuation in
            // Ensure we're on the main thread for UI operations
            DispatchQueue.main.async {
                let session = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: "aniledger"
                ) { callbackURL, error in
                    if let error = error {
                        // Check if user cancelled
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            continuation.resume(throwing: KiroError.authenticationFailed(reason: "User cancelled authentication"))
                        } else {
                            continuation.resume(throwing: KiroError.authenticationFailed(reason: error.localizedDescription))
                        }
                        return
                    }
                    
                    guard let callbackURL = callbackURL,
                          let token = Self.extractAccessToken(from: callbackURL) else {
                        continuation.resume(throwing: KiroError.authenticationFailed(reason: "AniList did not return an access token. Check that the client's redirect URI is \(Config.redirectUri)."))
                        return
                    }
                    
                    continuation.resume(returning: token)
                }
                
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                
                if !session.start() {
                    continuation.resume(throwing: KiroError.authenticationFailed(reason: "Failed to start authentication session"))
                }
            }
        }
    }
    
    /// Extract the access token from an implicit-grant callback URL.
    /// AniList puts the token in the URL fragment:
    /// `aniledger://auth-callback#access_token=...&token_type=Bearer&expires_in=31536000`
    static func extractAccessToken(from url: URL) -> AuthToken? {
        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment,
              !fragment.isEmpty else {
            return nil
        }

        var parser = URLComponents()
        parser.query = fragment
        let items = parser.queryItems ?? []

        guard let accessToken = items.first(where: { $0.name == "access_token" })?.value,
              !accessToken.isEmpty else {
            return nil
        }

        let tokenType = items.first(where: { $0.name == "token_type" })?.value ?? "Bearer"
        let expiresIn = items.first(where: { $0.name == "expires_in" })?.value.flatMap(Int.init) ?? 0

        return AuthToken(accessToken: accessToken, tokenType: tokenType, expiresIn: expiresIn)
    }
    
    // MARK: - User Profile
    
    /// Fetch user profile from AniList
    /// - Throws: KiroError if fetch fails
    private func fetchUserProfile() async throws {
        let query = FetchUserProfileQuery()
        let response: ViewerResponse = try await apiClient.execute(query: query)
        
        let userResponse = response.Viewer
        let user = AniListUser(
            id: userResponse.id,
            name: userResponse.name,
            avatar: userResponse.avatar.map { avatar in
                UserAvatar(large: avatar.large, medium: avatar.medium)
            }
        )
        
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    // MARK: - Logout
    
    /// Logout user and clear stored tokens
    func logout() {
        do {
            try keychainManager.delete(for: accessTokenKey)
        } catch {
            // Log error but continue with logout
            print("Failed to delete token from keychain: \(error)")
        }
        
        // Clear image cache
        ImageCacheManager.shared.clearCache()
        
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Token Refresh
    
    /// Return the stored access token. AniList implicit-grant tokens last one
    /// year and cannot be refreshed; an expired token triggers logout instead.
    /// - Returns: Current AuthToken
    /// - Throws: KiroError if token retrieval fails
    func refreshToken() async throws -> AuthToken {
        // AniList access tokens don't expire, so we just return the current token
        guard let accessToken = try keychainManager.retrieve(for: accessTokenKey) else {
            throw KiroError.authenticationFailed(reason: "No token found")
        }
        
        return AuthToken(
            accessToken: accessToken,
            tokenType: "Bearer",
            expiresIn: 0 // No expiration
        )
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window or any visible window
        if let keyWindow = NSApplication.shared.keyWindow {
            return keyWindow
        }
        
        // Fallback to any window
        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
            return window
        }
        
        // Last resort: create a new window
        let window = NSWindow()
        window.makeKeyAndOrderFront(nil)
        return window
    }
}
