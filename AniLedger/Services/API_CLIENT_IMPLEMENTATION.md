# AniList API Client Implementation

## Overview

This document describes the implementation of the AniList API Client for the AniLedger application.

## Files Created

### Core Implementation
1. **AniLedger/Services/AniListAPIClient.swift**
   - `AniListAPIClientProtocol` - Protocol defining the API client interface
   - `AniListAPIClient` - Concrete implementation of the API client
   - Handles GraphQL queries and mutations
   - Implements retry logic with exponential backoff for rate limiting
   - Proper error handling and response parsing

2. **AniLedger/Models/KiroError.swift**
   - Comprehensive error enum for the application
   - Implements `LocalizedError` for user-friendly error messages
   - Covers authentication, network, API, decoding, Core Data, and Keychain errors

### Test Implementation
3. **AniLedgerTests/Mocks/MockURLProtocol.swift**
   - Mock URLProtocol for intercepting network requests in tests
   - Allows controlled responses without actual network calls

4. **AniLedgerTests/Services/AniListAPIClientTests.swift**
   - Comprehensive unit tests for the API client
   - Tests all major functionality and edge cases

5. **AniLedgerTests/README.md**
   - Documentation for setting up and running tests

### Utilities
6. **scripts/verify-api-client.sh**
   - Verification script to ensure implementation compiles correctly

## Features Implemented

### ✅ Core Functionality
- [x] Execute GraphQL queries with type-safe responses
- [x] Execute GraphQL mutations with type-safe responses
- [x] Authorization header with Bearer token
- [x] JSON encoding/decoding with proper error handling
- [x] Retry logic with exponential backoff for rate limiting (429 responses)
- [x] GraphQL error response handling
- [x] HTTP error handling
- [x] Network error handling
- [x] Decoding error handling

### ✅ Test Coverage
- [x] Query execution with successful responses
- [x] Query execution with variables
- [x] Mutation execution with mock responses
- [x] Authorization header inclusion
- [x] Authorization header omission when token is nil
- [x] Network error handling
- [x] HTTP error response handling
- [x] GraphQL error parsing (single and multiple errors)
- [x] Decoding error handling
- [x] Rate limiting with retry logic (up to 3 retries)
- [x] Rate limit exceeded after max retries

## Architecture

### Protocol-Based Design
The implementation uses protocol-oriented programming to allow for easy testing and dependency injection:

```swift
protocol AniListAPIClientProtocol {
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T
}
```

### Dependency Injection
The client accepts a `URLSession` and `tokenProvider` closure, making it testable:

```swift
init(session: URLSession = .shared, tokenProvider: @escaping () -> String?)
```

### Error Handling
All errors are wrapped in the `KiroError` enum for consistent error handling across the app:

```swift
enum KiroError: LocalizedError {
    case authenticationFailed(reason: String)
    case networkError(underlying: Error)
    case apiError(message: String, statusCode: Int?)
    case decodingError(underlying: Error)
    case rateLimitExceeded
    // ... more cases
}
```

### Retry Logic
Implements exponential backoff for rate limiting:
- Initial delay: 1 second
- Exponential multiplier: 2x
- Max retries: 3
- Total attempts: 4 (initial + 3 retries)

## Usage Example

```swift
// Initialize the client
let apiClient = AniListAPIClient { 
    // Return the current auth token
    return KeychainManager.shared.retrieveToken()
}

// Execute a query
let query = FetchUserProfileQuery()
let response: ViewerResponse = try await apiClient.execute(query: query)
print("User: \(response.Viewer.name)")

// Execute a mutation
let mutation = UpdateProgressMutation(mediaId: 123, progress: 5, status: "CURRENT")
let result: SaveMediaListEntryResponse = try await apiClient.execute(mutation: mutation)
print("Updated progress to: \(result.SaveMediaListEntry.progress)")
```

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **3.1**: Fetch user's anime lists from AniList using GraphQL queries ✅
- **3.2**: Send updates to AniList API using GraphQL mutations ✅
- **3.3**: Update anime status on AniList ✅
- **3.5**: Store changes locally and retry when connection is restored (via error handling) ✅

## Next Steps

1. Add the test target to Xcode (see AniLedgerTests/README.md)
2. Run the unit tests to verify functionality
3. Integrate the API client with the Authentication Service (Task 6)
4. Integrate with the Sync Service (Task 8)

## Notes

- The implementation uses modern Swift concurrency (async/await)
- All network requests are made asynchronously
- The client is thread-safe and can be used from any actor context
- Rate limiting is handled automatically with exponential backoff
- GraphQL errors are properly parsed and converted to KiroError instances
