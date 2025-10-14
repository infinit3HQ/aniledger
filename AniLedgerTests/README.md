# AniLedger Tests

This directory contains unit tests for the AniLedger application.

## Setup

To run these tests, you need to add a test target to the Xcode project:

1. Open `AniLedger.xcodeproj` in Xcode
2. Go to **File > New > Target...**
3. Select **macOS > Unit Testing Bundle**
4. Name it `AniLedgerTests`
5. Set the target to be tested to `AniLedger`
6. Click **Finish**

## Test Structure

- `Services/AniListAPIClientTests.swift` - Tests for the AniList API client
- `Mocks/MockURLProtocol.swift` - Mock URLProtocol for testing network requests

## Running Tests

### Via Xcode
1. Select the `AniLedgerTests` scheme
2. Press `Cmd + U` to run all tests
3. Or click the diamond icon next to individual test methods to run specific tests

### Via Command Line
```bash
xcodebuild test -project AniLedger.xcodeproj -scheme AniLedgerTests -destination 'platform=macOS'
```

## Test Coverage

### AniListAPIClientTests
- ✅ Query execution with successful responses
- ✅ Query execution with variables
- ✅ Mutation execution
- ✅ Authorization header inclusion
- ✅ Authorization header omission when token is nil
- ✅ Network error handling
- ✅ HTTP error response handling
- ✅ GraphQL error parsing (single and multiple errors)
- ✅ Decoding error handling
- ✅ Rate limiting with retry logic
- ✅ Rate limit exceeded after max retries

## Notes

The tests use `MockURLProtocol` to intercept network requests and provide controlled responses without making actual API calls. This ensures tests are:
- Fast
- Reliable
- Independent of network connectivity
- Independent of AniList API availability
