//
//  SettingsViewModelTests.swift
//  AniLedgerTests
//
//  Unit tests for SettingsViewModel
//

import XCTest
@testable import AniLedger

@MainActor
class SettingsViewModelTests: XCTestCase {
    var mockKeychainManager: MockKeychainManager!
    var mockApiClient: MockAniListAPIClient!
    var authService: AuthenticationService!
    var coreDataStack: CoreDataStack!
    var mockSyncService: MockSyncService!
    
    override func setUp() {
        super.setUp()
        mockKeychainManager = MockKeychainManager()
        mockApiClient = MockAniListAPIClient()
        authService = AuthenticationService(
            keychainManager: mockKeychainManager,
            apiClient: mockApiClient
        )
        coreDataStack = CoreDataStack.preview
        mockSyncService = MockSyncService()
    }
    
    override func tearDown() {
        mockKeychainManager = nil
        mockApiClient = nil
        authService = nil
        coreDataStack = nil
        mockSyncService = nil
        super.tearDown()
    }
    
    func testToggleAutoSync() {
        let viewModel = SettingsViewModel(
            authenticationService: authService,
            coreDataStack: coreDataStack,
            syncService: mockSyncService,
            notificationService: nil
        )
        
        let initial = viewModel.autoSyncEnabled
        viewModel.toggleAutoSync()
        XCTAssertEqual(viewModel.autoSyncEnabled, !initial)
    }
    
    func testSetThemePreference() {
        let viewModel = SettingsViewModel(
            authenticationService: authService,
            coreDataStack: coreDataStack,
            syncService: mockSyncService,
            notificationService: nil
        )
        
        viewModel.setTheme(.dark)
        XCTAssertEqual(viewModel.themePreference, .dark)
        
        viewModel.setTheme(.light)
        XCTAssertEqual(viewModel.themePreference, .light)
    }
    
    func testLogoutClearsState() {
        let viewModel = SettingsViewModel(
            authenticationService: authService,
            coreDataStack: coreDataStack,
            syncService: mockSyncService,
            notificationService: nil
        )
        
        viewModel.requestLogout()
        XCTAssertTrue(viewModel.showLogoutConfirmation)
        
        viewModel.logout()
        
        // Give logout Task time to complete
        let expectation = XCTestExpectation(description: "Logout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.authService.isAuthenticated)
            XCTAssertNil(viewModel.user)
            XCTAssertFalse(viewModel.showLogoutConfirmation)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
