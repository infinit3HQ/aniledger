//
//  AuthenticationService.swift
//  AniLedger
//
//  Created by Kiro on 10/13/2025.
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
    private let clientId = Config.aniListClientId
    private let clientSecret = Config.aniListClientSecret
    private let redirectUri = Config.redirectUri
    private let authorizationEndpoint = Config.authorizationUrl
    private let tokenEndpoint = "https://anilist.co/api/v2/oauth/token"
    
    // Keychain keys - using Config constants
    private let accessTokenKey = Config.keychainAccessTokenKey
    
    // MARK: - Initialization
    
    init(keychainManager: KeychainManagerProtocol, apiClient: AniListAPIClientProtocol) {
        self.keychainManager = keychainManager
        self.apiClient = apiClient
        super.init()
        
        // Check if user is already authenticated
        checkAuthenticationState()
    }
    
    // MARK: - Authentication State
    
    /// Check if user has a valid token stored
    private func checkAuthenticationState() {
        do {
            if let token = try keychainManager.retrieve(for: accessTokenKey), !token.isEmpty {
                // Fetch user profile in background BEFORE setting isAuthenticated
                Task {
                    do {
                        try await fetchUserProfile()
                        await MainActor.run {
                            isAuthenticated = true
                        }
                    } catch {
                        // If profile fetch fails, still mark as authenticated
                        // User can retry sync manually
                        await MainActor.run {
                            isAuthenticated = true
                        }
                    }
                }
            }
        } catch {
            isAuthenticated = false
        }
    }
    
    // MARK: - Authentication
    
    /// Initiate OAuth2 authentication flow
    /// - Returns: AuthToken containing access token and metadata
    /// - Throws: KiroError if authentication fails
    func authenticate() async throws -> AuthToken {
        // Generate authorization URL
        guard let authURL = generateAuthorizationURL() else {
            throw KiroError.authenticationFailed(reason: "Failed to generate authorization URL")
        }
        
        // Present authentication session
        let authCode = try await presentAuthenticationSession(url: authURL)
        
        // Exchange authorization code for access token
        let token = try await exchangeCodeForToken(code: authCode)
        
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
    
    /// Generate OAuth2 authorization URL
    /// - Returns: URL for authorization or nil if invalid
    private func generateAuthorizationURL() -> URL? {
        print("🔑 Using Client ID: \(clientId)")
        print("🔗 Redirect URI: \(redirectUri)")
        
        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code")
        ]
        
        if let url = components?.url {
            print("📍 Authorization URL: \(url)")
        }
        
        return components?.url
    }
    
    /// Present ASWebAuthenticationSession for OAuth flow
    /// - Parameter url: Authorization URL
    /// - Returns: Authorization code from callback
    /// - Throws: KiroError if authentication fails or is cancelled
    private func presentAuthenticationSession(url: URL) async throws -> String {
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
                            print("❌ Authentication error: \(error.localizedDescription)")
                            print("❌ Error code: \((error as NSError).code)")
                            continuation.resume(throwing: KiroError.authenticationFailed(reason: error.localizedDescription))
                        }
                        return
                    }
                    
                    guard let callbackURL = callbackURL,
                          let code = self.extractAuthorizationCode(from: callbackURL) else {
                        continuation.resume(throwing: KiroError.authenticationFailed(reason: "Failed to extract authorization code"))
                        return
                    }
                    
                    print("✅ Successfully received authorization code")
                    continuation.resume(returning: code)
                }
                
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                
                print("🔐 Starting authentication session with URL: \(url)")
                if !session.start() {
                    continuation.resume(throwing: KiroError.authenticationFailed(reason: "Failed to start authentication session"))
                }
            }
        }
    }
    
    /// Extract authorization code from callback URL
    /// - Parameter url: Callback URL containing the code
    /// - Returns: Authorization code or nil if not found
    private func extractAuthorizationCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return queryItems.first(where: { $0.name == "code" })?.value
    }
    
    /// Exchange authorization code for access token
    /// - Parameter code: Authorization code from OAuth callback
    /// - Returns: AuthToken with access token
    /// - Throws: KiroError if token exchange fails
    private func exchangeCodeForToken(code: String) async throws -> AuthToken {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri,
            "code": code
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔄 Exchanging authorization code for token...")
        print("📤 Request URL: \(tokenEndpoint)")
        print("📤 Request body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KiroError.invalidResponse
        }
        
        print("📥 Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            // Try to parse error response
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw KiroError.apiError(message: "Token exchange failed", statusCode: httpResponse.statusCode)
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        print("✅ Successfully received access token")
        
        return AuthToken(
            accessToken: tokenResponse.access_token,
            tokenType: tokenResponse.token_type,
            expiresIn: tokenResponse.expires_in
        )
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
    
    /// Refresh access token (AniList tokens don't expire, so this is a no-op)
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

// MARK: - Token Response Model

private struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}
