//
//  AuthenticationServiceTests.swift
//  AniLedgerTests
//
//  Created by Kiro on 10/13/2025.
//

import XCTest
@testable import AniLedger

final class AuthenticationServiceTests: XCTestCase {
    var authService: AuthenticationService!
    var mockKeychainManager: MockKeychainManager!
    var mockAPIClient: MockAniListAPIClient!
    
    override func setUp() {
        super.setUp()
        
        mockKeychainManager = MockKeychainManager()
        mockAPIClient = MockAniListAPIClient()
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
    }
    
    override func tearDown() {
        authService = nil
        mockKeychainManager = nil
        mockAPIClient = nil
        super.tearDown()
    }
    
    // MARK: - Authentication State Tests
    
    func testIsAuthenticatedWhenTokenExists() {
        // Given
        try? mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Then
        XCTAssertTrue(authService.isAuthenticated)
    }
    
    func testIsNotAuthenticatedWhenNoToken() {
        // Given - no token in keychain
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    func testIsNotAuthenticatedWhenKeychainFails() {
        // Given
        mockKeychainManager.shouldThrowOnRetrieve = true
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    // MARK: - Token Storage Tests
    
    func testTokenStorageAfterAuthentication() async throws {
        // Given
        let mockUserResponse = GraphQLResponse<ViewerResponse>(
            data: ViewerResponse(
                Viewer: UserResponse(
                    id: 123,
                    name: "TestUser",
                    avatar: nil
                )
            ),
            errors: nil
        )
        mockAPIClient.queryResult = mockUserResponse
        
        // Note: We can't fully test the OAuth flow without mocking ASWebAuthenticationSession
        // This test verifies token storage logic
        
        // When - manually store token to simulate successful auth
        try mockKeychainManager.save(token: "test_access_token", for: "anilist_access_token")
        
        // Then
        let retrievedToken = try mockKeychainManager.retrieve(for: "anilist_access_token")
        XCTAssertEqual(retrievedToken, "test_access_token")
        XCTAssertEqual(mockKeychainManager.saveCallCount, 1)
    }
    
    func testTokenRetrievalFromKeychain() throws {
        // Given
        try mockKeychainManager.save(token: "stored_token", for: "anilist_access_token")
        
        // When
        let token = try mockKeychainManager.retrieve(for: "anilist_access_token")
        
        // Then
        XCTAssertEqual(token, "stored_token")
    }
    
    // MARK: - Logout Tests
    
    func testLogoutClearsToken() {
        // Given
        try? mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        XCTAssertTrue(authService.isAuthenticated)
        
        // When
        authService.logout()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
        XCTAssertEqual(mockKeychainManager.deleteCallCount, 1)
        
        let token = try? mockKeychainManager.retrieve(for: "anilist_access_token")
        XCTAssertNil(token)
    }
    
    func testLogoutHandlesKeychainError() {
        // Given
        try? mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        mockKeychainManager.shouldThrowOnDelete = true
        
        // When - should not crash even if keychain delete fails
        authService.logout()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    func testLogoutClearsCurrentUser() {
        // Given
        try? mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        
        let mockUserResponse = GraphQLResponse<ViewerResponse>(
            data: ViewerResponse(
                Viewer: UserResponse(
                    id: 123,
                    name: "TestUser",
                    avatar: AvatarResponse(large: "url", medium: "url")
                )
            ),
            errors: nil
        )
        mockAPIClient.queryResult = mockUserResponse
        
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Wait for user profile to be fetched
        let expectation = XCTestExpectation(description: "User profile fetched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When
        authService.logout()
        
        // Then
        XCTAssertNil(authService.currentUser)
    }
    
    // MARK: - User Profile Tests
    
    func testFetchUserProfileSuccess() async throws {
        // Given
        try mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        
        let mockUserResponse = GraphQLResponse<ViewerResponse>(
            data: ViewerResponse(
                Viewer: UserResponse(
                    id: 456,
                    name: "AniListUser",
                    avatar: AvatarResponse(
                        large: "https://example.com/large.jpg",
                        medium: "https://example.com/medium.jpg"
                    )
                )
            ),
            errors: nil
        )
        mockAPIClient.queryResult = mockUserResponse
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Wait for async user profile fetch
        let expectation = XCTestExpectation(description: "User profile fetched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.id, 456)
        XCTAssertEqual(authService.currentUser?.name, "AniListUser")
        XCTAssertEqual(authService.currentUser?.avatar?.large, "https://example.com/large.jpg")
    }
    
    func testFetchUserProfileWithoutAvatar() async throws {
        // Given
        try mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        
        let mockUserResponse = GraphQLResponse<ViewerResponse>(
            data: ViewerResponse(
                Viewer: UserResponse(
                    id: 789,
                    name: "NoAvatarUser",
                    avatar: nil
                )
            ),
            errors: nil
        )
        mockAPIClient.queryResult = mockUserResponse
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Wait for async user profile fetch
        let expectation = XCTestExpectation(description: "User profile fetched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.id, 789)
        XCTAssertEqual(authService.currentUser?.name, "NoAvatarUser")
        XCTAssertNil(authService.currentUser?.avatar)
    }
    
    // MARK: - Error Handling Tests
    
    func testAuthenticationFailsWhenAPIReturnsError() async throws {
        // Given
        try mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        
        let mockErrorResponse = GraphQLResponse<ViewerResponse>(
            data: nil,
            errors: [
                GraphQLError(
                    message: "Invalid token",
                    status: 401,
                    locations: nil
                )
            ]
        )
        mockAPIClient.queryResult = mockErrorResponse
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Wait for async user profile fetch attempt
        let expectation = XCTestExpectation(description: "User profile fetch attempted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - user should still be authenticated but profile fetch failed
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    func testAuthenticationFailsWhenNetworkError() async throws {
        // Given
        try mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        mockAPIClient.shouldThrowError = KiroError.networkError(underlying: URLError(.notConnectedToInternet))
        
        // When
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient
        )
        
        // Wait for async user profile fetch attempt
        let expectation = XCTestExpectation(description: "User profile fetch attempted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - user should still be authenticated but profile fetch failed
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    func testKeychainSaveFailure() throws {
        // Given
        mockKeychainManager.shouldThrowOnSave = true
        
        // When/Then
        XCTAssertThrowsError(
            try mockKeychainManager.save(token: "test_token", for: "anilist_access_token")
        ) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }
    
    func testKeychainRetrieveFailure() throws {
        // Given
        mockKeychainManager.shouldThrowOnRetrieve = true
        
        // When/Then
        XCTAssertThrowsError(
            try mockKeychainManager.retrieve(for: "anilist_access_token")
        ) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshTokenReturnsCurrentToken() async throws {
        // Given
        try mockKeychainManager.save(token: "existing_token", for: "anilist_access_token")
        
        // When
        let token = try await authService.refreshToken()
        
        // Then
        XCTAssertEqual(token.accessToken, "existing_token")
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.expiresIn, 0) // AniList tokens don't expire
    }
    
    func testRefreshTokenFailsWhenNoToken() async throws {
        // Given - no token in keychain
        
        // When/Then
        do {
            _ = try await authService.refreshToken()
            XCTFail("Expected error to be thrown")
        } catch let error as KiroError {
            if case .authenticationFailed(let reason) = error {
                XCTAssertTrue(reason.contains("No token found"))
            } else {
                XCTFail("Expected authenticationFailed error")
            }
        }
    }
}
