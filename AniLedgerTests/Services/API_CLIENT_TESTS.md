# AniListAPIClient Unit Tests

## Overview

This document describes the comprehensive unit tests implemented for the `AniListAPIClient` class. All tests use `MockURLProtocol` to simulate network responses without making actual HTTP requests.

## Test Coverage

### 1. Query Execution Tests

#### `testExecuteQuerySuccess()`
- **Purpose**: Verifies successful GraphQL query execution
- **Scenario**: Executes a `FetchUserProfileQuery` with a valid response
- **Validates**: 
  - Response is properly decoded
  - Data fields are correctly mapped
  - Query execution completes without errors

#### `testExecuteQueryWithVariables()`
- **Purpose**: Verifies query variables are properly encoded and sent
- **Scenario**: Executes a `SearchAnimeQuery` with search term "Naruto"
- **Validates**:
  - Variables are included in the request body
  - Variables are properly JSON-encoded
  - Query string and variables are both present

### 2. Mutation Execution Tests

#### `testExecuteMutationSuccess()`
- **Purpose**: Verifies successful GraphQL mutation execution
- **Scenario**: Executes an `UpdateProgressMutation` to update anime progress
- **Validates**:
  - Mutation response is properly decoded
  - Updated values are correctly returned
  - Mutation execution completes without errors

### 3. Authorization Header Tests

#### `testAuthorizationHeaderIncluded()`
- **Purpose**: Verifies Bearer token is included in requests when available
- **Scenario**: Executes a query with a valid token
- **Validates**:
  - Authorization header is present
  - Header format is "Bearer {token}"
  - Token value matches the provided token

#### `testAuthorizationHeaderNotIncludedWhenTokenIsNil()`
- **Purpose**: Verifies requests work without authentication when token is nil
- **Scenario**: Executes a query with no token (for public queries)
- **Validates**:
  - Authorization header is not present
  - Request still executes successfully
  - No authentication errors occur

### 4. Error Handling Tests

#### `testNetworkError()`
- **Purpose**: Verifies network errors are properly propagated
- **Scenario**: Simulates a network connectivity failure
- **Validates**:
  - URLError is thrown
  - Error type is correctly identified
  - No false success is reported

#### `testHTTPErrorResponse()`
- **Purpose**: Verifies HTTP error responses are handled correctly
- **Scenario**: Simulates a 500 Internal Server Error
- **Validates**:
  - KiroError.apiError is thrown
  - Status code is correctly captured
  - Error message is included

#### `testGraphQLErrorParsing()`
- **Purpose**: Verifies GraphQL errors in response are properly parsed
- **Scenario**: Simulates an authentication error from AniList API
- **Validates**:
  - GraphQL errors are detected
  - Error message is extracted
  - Status code from error is captured

#### `testMultipleGraphQLErrors()`
- **Purpose**: Verifies multiple GraphQL errors are handled
- **Scenario**: Simulates a response with multiple error objects
- **Validates**:
  - All error messages are combined
  - Error messages are joined with commas
  - First error's status code is used

#### `testDecodingError()`
- **Purpose**: Verifies decoding errors are properly handled
- **Scenario**: Simulates a response with invalid data types
- **Validates**:
  - KiroError.decodingError is thrown
  - Underlying decoding error is captured
  - Invalid data doesn't crash the app

### 5. Rate Limiting Tests

#### `testRateLimitRetry()`
- **Purpose**: Verifies retry logic works for rate limit errors
- **Scenario**: Simulates 429 responses that eventually succeed
- **Validates**:
  - Request is retried up to max retries
  - Exponential backoff is applied
  - Success is achieved after retries
  - Request count matches expected retries

#### `testRateLimitExceededAfterMaxRetries()`
- **Purpose**: Verifies rate limit error is thrown after max retries
- **Scenario**: Simulates persistent 429 responses
- **Validates**:
  - KiroError.rateLimitExceeded is thrown
  - Max retries (3) are attempted
  - Total request count is 4 (initial + 3 retries)
  - Error is properly propagated

## Test Infrastructure

### MockURLProtocol
- Custom URLProtocol subclass for mocking network responses
- Allows complete control over HTTP responses
- Supports error simulation
- Thread-safe request handling

### Test Setup
- Each test creates a fresh `URLSession` with `MockURLProtocol`
- API client is initialized with mock session and token provider
- Token can be modified per test to test different scenarios

### Test Teardown
- Cleans up API client, session, and token
- Resets `MockURLProtocol.requestHandler` to prevent test interference

## Requirements Coverage

This test suite satisfies the following requirements from the design document:

- **Requirement 3.1**: Fetch user's anime lists from AniList using GraphQL queries
- **Requirement 3.2**: Send updates to AniList API using GraphQL mutations
- **Requirement 3.3**: Change anime status on AniList
- **Requirement 3.5**: Store changes locally and retry when connection is restored

## Running the Tests

### Option 1: Xcode
1. Open `AniLedger.xcodeproj` in Xcode
2. Select the test file in the navigator
3. Click the diamond icon next to the test class or individual test methods
4. Or use `Cmd+U` to run all tests

### Option 2: Command Line
```bash
# Run all tests
xcodebuild test -project AniLedger.xcodeproj -scheme AniLedger -destination 'platform=macOS'

# Run only API client tests
xcodebuild test -project AniLedger.xcodeproj -scheme AniLedger -destination 'platform=macOS' -only-testing:AniLedgerTests/AniListAPIClientTests
```

### Option 3: Test Script
```bash
./scripts/run-api-client-tests.sh
```

## Test Maintenance

When modifying the `AniListAPIClient`:
1. Update corresponding tests to reflect changes
2. Add new tests for new functionality
3. Ensure all tests pass before committing
4. Maintain test coverage above 90%

## Future Enhancements

Potential additional tests to consider:
- Test concurrent request handling
- Test request cancellation
- Test custom timeout handling
- Test response caching behavior
- Performance tests for large responses
