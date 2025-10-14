//
//  LoginView.swift
//  AniLedger
//
//  Login view for AniList authentication
//

import SwiftUI

struct LoginView: View {
    // MARK: - Dependencies
    
    @ObservedObject var authenticationService: AuthenticationService
    
    // MARK: - State
    
    @State private var isAuthenticating = false
    @State private var authError: KiroError?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.11, blue: 0.22),
                    Color(red: 0.05, green: 0.15, blue: 0.28)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App branding
                VStack(spacing: 16) {
                    // App icon placeholder
                    Image(systemName: "tv.and.mediabox")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("AniLedger")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Track your anime journey")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Login section
                VStack(spacing: 24) {
                    // AniList branding info
                    VStack(spacing: 8) {
                        Text("Sign in with your AniList account")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Sync your anime lists and track your progress")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Login button
                    Button(action: handleLogin) {
                        HStack(spacing: 12) {
                            if isAuthenticating {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                            }
                            
                            Text(isAuthenticating ? "Authenticating..." : "Login with AniList")
                                .font(.headline)
                        }
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.13, green: 0.47, blue: 0.91),
                                    Color(red: 0.10, green: 0.38, blue: 0.75)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAuthenticating)
                    .scaleEffect(isAuthenticating ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isAuthenticating)
                    
                    // Privacy note
                    Text("We'll never share your data with third parties")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("Powered by AniList")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 16) {
                        Link("About AniList", destination: URL(string: "https://anilist.co/about")!)
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Link("Privacy Policy", destination: URL(string: "https://anilist.co/terms")!)
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                .padding(.bottom, 32)
            }
            
            // Loading overlay
            if isAuthenticating {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .errorAlert($authError, retryAction: handleLogin)
    }
    
    // MARK: - Actions
    
    /// Handle login button tap
    private func handleLogin() {
        isAuthenticating = true
        authError = nil
        
        Task {
            do {
                _ = try await authenticationService.authenticate()
                // Authentication successful - the app will automatically navigate
                // based on the isAuthenticated state change
            } catch let error as KiroError {
                await MainActor.run {
                    authError = error
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    authError = .authenticationFailed(reason: error.localizedDescription)
                    isAuthenticating = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Login View") {
    LoginView(
        authenticationService: AuthenticationService(
            keychainManager: MockKeychainManager(),
            apiClient: MockAniListAPIClient()
        )
    )
}

// MARK: - Mock Services for Preview

private class MockKeychainManager: KeychainManagerProtocol {
    func save(token: String, for key: String) throws {}
    func retrieve(for key: String) throws -> String? { nil }
    func delete(for key: String) throws {}
}

private class MockAniListAPIClient: AniListAPIClientProtocol {
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T {
        throw KiroError.invalidResponse
    }
    
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T {
        throw KiroError.invalidResponse
    }
}
