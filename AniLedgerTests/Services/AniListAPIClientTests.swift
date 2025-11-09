//
//  AniListAPIClientTests.swift
//  AniLedgerTests
//
//  Created by Niraj Dilshan on 10/13/2025.
//

import XCTest
@testable import AniLedger

final class AniListAPIClientTests: XCTestCase {
    var apiClient: AniListAPIClient!
    var mockSession: URLSession!
    var mockToken: String?
    
    override func setUp() {
        super.setUp()
        
        // Configure mock URLSession
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        // Initialize API client with mock session
        mockToken = "test_token_123"
        apiClient = AniListAPIClient(session: mockSession) { [weak self] in
            return self?.mockToken
        }
    }
    
    override func tearDown() {
        apiClient = nil
        mockSession = nil
        mockToken = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    // MARK: - Query Execution Tests
    
    func testExecuteQuerySuccess() async throws {
        // Given
        let expectedResponse = """
        {
            "data": {
                "Viewer": {
                    "id": 123,
                    "name": "TestUser",
                    "avatar": {
                        "large": "https://example.com/avatar.jpg",
                        "medium": "https://example.com/avatar_medium.jpg"
                    }
                }
            }
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedResponse.data(using: .utf8))
        }
        
        // When
        let query = FetchUserProfileQuery()
        let result: ViewerResponse = try await apiClient.execute(query: query)
        
        // Then
        XCTAssertEqual(result.Viewer.id, 123)
        XCTAssertEqual(result.Viewer.name, "TestUser")
        XCTAssertEqual(result.Viewer.avatar?.large, "https://example.com/avatar.jpg")
    }
    
    func testExecuteQueryWithVariables() async throws {
        // Given
        let expectedResponse = """
        {
            "data": {
                "Page": {
                    "media": []
                }
            }
        }
        """
        
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedResponse.data(using: .utf8))
        }
        
        // When
        let query = SearchAnimeQuery(searchTerm: "Naruto")
        let _: PageResponse = try await apiClient.execute(query: query)
        
        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertNotNil(capturedRequest?.httpBody)
        
        if let body = capturedRequest?.httpBody {
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            let variables = json?["variables"] as? [String: Any]
            XCTAssertEqual(variables?["search"] as? String, "Naruto")
        }
    }
    
    // MARK: - Mutation Execution Tests
    
    func testExecuteMutationSuccess() async throws {
        // Given
        let expectedResponse = """
        {
            "data": {
                "SaveMediaListEntry": {
                    "id": 456,
                    "progress": 5,
                    "status": "CURRENT",
                    "media": {
                        "id": 789
                    }
                }
            }
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedResponse.data(using: .utf8))
        }
        
        // When
        let mutation = UpdateProgressMutation(mediaId: 789, progress: 5, status: "CURRENT")
        let result: SaveMediaListEntryResponse = try await apiClient.execute(mutation: mutation)
        
        // Then
        XCTAssertEqual(result.SaveMediaListEntry.id, 456)
        XCTAssertEqual(result.SaveMediaListEntry.progress, 5)
        XCTAssertEqual(result.SaveMediaListEntry.status, "CURRENT")
    }
    
    // MARK: - Authorization Header Tests
    
    func testAuthorizationHeaderIncluded() async throws {
        // Given
        let expectedResponse = """
        {
            "data": {
                "Viewer": {
                    "id": 123,
                    "name": "TestUser",
                    "avatar": null
                }
            }
        }
        """
        
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedResponse.data(using: .utf8))
        }
        
        // When
        let query = FetchUserProfileQuery()
        let _: ViewerResponse = try await apiClient.execute(query: query)
        
        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer test_token_123"
        )
    }
    
    func testAuthorizationHeaderNotIncludedWhenTokenIsNil() async throws {
        // Given
        mockToken = nil
        let expectedResponse = """
        {
            "data": {
                "Page": {
                    "media": []
                }
            }
        }
        """
        
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedResponse.data(using: .utf8))
        }
        
        // When
        let query = TrendingAnimeQuery()
        let _: PageResponse = try await apiClient.execute(query: query)
        
        // Then
        XCTAssertNotNil(capturedRequest)
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkError() async throws {
        // Given
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        // When/Then
        let query = FetchUserProfileQuery()
        do {
            let _: ViewerResponse = try await apiClient.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testHTTPErrorResponse() async throws {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            let errorData = "Internal Server Error".data(using: .utf8)
            return (response, errorData)
        }
        
        // When/Then
        let query = FetchUserProfileQuery()
        do {
            let _: ViewerResponse = try await apiClient.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch let error as KiroError {
            if case .apiError(let message, let statusCode) = error {
                XCTAssertEqual(statusCode, 500)
                XCTAssertTrue(message.contains("Internal Server Error"))
            } else {
                XCTFail("Expected apiError")
            }
        }
    }
    
    func testGraphQLErrorParsing() async throws {
        // Given
        let errorResponse = """
        {
            "data": null,
            "errors": [
                {
                    "message": "Invalid token",
                    "status": 401,
                    "locations": [
                        {
                            "line": 1,
                            "column": 1
                        }
                    ]
                }
            ]
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorResponse.data(using: .utf8))
        }
        
        // When/Then
        let query = FetchUserProfileQuery()
        do {
            let _: ViewerResponse = try await apiClient.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch let error as KiroError {
            if case .apiError(let message, let statusCode) = error {
                XCTAssertTrue(message.contains("Invalid token"))
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("Expected apiError")
            }
        }
    }
    
    func testMultipleGraphQLErrors() async throws {
        // Given
        let errorResponse = """
        {
            "data": null,
            "errors": [
                {
                    "message": "Error 1",
                    "status": 400
                },
                {
                    "message": "Error 2",
                    "status": 400
                }
            ]
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorResponse.data(using: .utf8))
        }
        
        // When/Then
        let query = FetchUserProfileQuery()
        do {
            let _: ViewerResponse = try await apiClient.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch let error as KiroError {
            if case .apiError(let message, _) = error {
                XCTAssertTrue(message.contains("Error 1"))
                XCTAssertTrue(message.contains("Error 2"))
            } else {
                XCTFail("Expected apiError")
            }
        }
    }
    
    func testDecodingError() async throws {
        // Given
        let invalidResponse = """
        {
            "data": {
                "Viewer": {
                    "id": "not_a_number",
                    "name": "TestUser"
                }
            }
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, invalidResponse.data(using: .utf8))
        }
        
        // When/Then
        let query = FetchUserProfileQuery()
        do {
            let _: ViewerResponse = try await apiClient.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch let error as KiroError {
            if case .decodingError = error {
                // Expected error
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        }
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimitRetry() async throws {
        // Given
        var requestCount = 0
        let successResponse = """
        {
            "data": {
                "Viewer": {
                    "id": 123,
                    "name": "TestUser",
                    "avatar": null
                }
            }
        }
        """
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            
            if requestCount < 3 {
                // Return 429 for first two requests
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, nil)
            } else {
                // Return success on third request
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, successResponse.data(using: .utf8))
            }
        }
        
        // When
        let query = FetchUserProfileQuery()
        let result: ViewerResponse = try await apiClient.execute(query: query)
        
        // Then
        XCTAssertEqual(requestCount, 3)
        XCTAssertEqual(result.Viewer.id, 123)
    }
    
    func testRateLimitExceededAfterMaxRetries() async throws {
        // Given
        var requestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }
        
        // When/Then
        let query = FetchUserProfileQuery()
        do {
            let _: ViewerResponse = try await apiClient.execute(query: query)
            XCTFail("Expected error to be thrown")
        } catch let error as KiroError {
            if case .rateLimitExceeded = error {
                // Expected error
                XCTAssertEqual(requestCount, 4) // Initial + 3 retries
            } else {
                XCTFail("Expected rateLimitExceeded, got \(error)")
            }
        }
    }
}
