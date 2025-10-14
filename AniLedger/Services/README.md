# Services

This directory contains service layer implementations for AniLedger.

## KeychainManager

Secure storage manager for authentication tokens using the macOS Keychain.

### Features

- **Secure Storage**: Uses macOS Security framework for secure token storage
- **Service Identifier**: All items stored with service identifier "com.aniledger"
- **Error Handling**: Comprehensive error handling with descriptive error messages
- **Overwrite Support**: Automatically overwrites existing tokens with the same key
- **Thread-Safe**: Keychain operations are thread-safe by design

### Usage

```swift
let keychainManager = KeychainManager()

// Save a token
try keychainManager.save(token: "access_token_123", for: "auth_token")

// Retrieve a token
if let token = try keychainManager.retrieve(for: "auth_token") {
    print("Token: \(token)")
}

// Delete a token
try keychainManager.delete(for: "auth_token")
```

### Error Handling

The KeychainManager throws `KeychainError` for various failure scenarios:

- `.invalidData`: Data format is invalid for Keychain operations
- `.saveFailed(status:)`: Failed to save to Keychain
- `.retrieveFailed(status:)`: Failed to retrieve from Keychain
- `.deleteFailed(status:)`: Failed to delete from Keychain

### Testing

Comprehensive unit tests are available in `AniLedgerTests/KeychainManagerTests.swift`:

- Save, retrieve, and delete operations
- Overwriting existing keys
- Error handling for invalid operations
- Special characters and Unicode support
- Concurrent access testing
- Full lifecycle testing

### Requirements Coverage

This implementation satisfies:
- **Requirement 1.3**: Secure token storage using Keychain
- **Requirement 1.5**: Token clearing on logout
