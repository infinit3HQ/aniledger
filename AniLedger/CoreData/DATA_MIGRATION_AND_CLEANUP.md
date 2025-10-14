# Data Migration and Cleanup Implementation

## Overview

This document describes the data migration and cleanup features implemented in AniLedger to handle Core Data schema changes, corrupted data recovery, and user data management.

## Features

### 1. Automatic Lightweight Migration

**Location**: `CoreDataStack.swift`

The Core Data stack is configured to automatically handle lightweight migrations when the schema changes:

```swift
let description = persistentContainer.persistentStoreDescriptions.first
description?.shouldMigrateStoreAutomatically = true
description?.shouldInferMappingModelAutomatically = true
```

**Benefits**:
- Seamless updates when adding new attributes or relationships
- No manual migration code needed for simple schema changes
- Automatic mapping model inference

**Supported Changes**:
- Adding new entities
- Adding new attributes with default values
- Adding new relationships
- Renaming entities or attributes (with renaming identifiers)
- Changing attribute types (with compatible types)

### 2. Migration Failure Recovery

**Location**: `CoreDataStack.handleMigrationFailure(storeURL:)`

If automatic migration fails (e.g., due to corrupted data or incompatible schema changes), the system automatically:

1. Logs the error for debugging
2. Removes corrupted store files (main, WAL, SHM)
3. Recreates a fresh persistent store
4. Allows the app to continue running

**Files Cleaned**:
- `AniLedger.sqlite` - Main database file
- `AniLedger.sqlite-wal` - Write-Ahead Log file
- `AniLedger.sqlite-shm` - Shared Memory file

### 3. Re-sync from AniList

**Location**: `SettingsViewModel.performResync()` and `SettingsView` Data Management section

Users can manually trigger a complete re-sync from AniList when:
- Local data becomes corrupted
- Data is out of sync with AniList
- They want a fresh start

**Process**:
1. User clicks "Re-sync from AniList" button
2. Confirmation dialog appears
3. System destroys and recreates the persistent store
4. Performs full sync from AniList API
5. Shows success or error message

**UI Location**: Settings → Data Management → Re-sync from AniList

### 4. Clear Local Data

**Location**: `SettingsViewModel.clearLocalData()` and `SettingsView` Data Management section

Users can manually clear all local anime data to:
- Free up disk space
- Remove cached data
- Start fresh without re-syncing

**Process**:
1. User clicks "Clear Local Data" button
2. Confirmation dialog appears
3. System deletes all Core Data entities:
   - UserAnimeEntity (user's anime list entries)
   - AnimeEntity (cached anime metadata)
   - SyncQueueEntity (pending sync operations)
4. Shows success or error message

**UI Location**: Settings → Data Management → Clear Local Data

### 5. Optional Data Cleanup on Logout

**Location**: `SettingsViewModel.logout()` and `SettingsView` Logout section

Users can choose whether to clear local data when logging out:

**Toggle**: "Clear data on logout"
- **Enabled**: All local anime data is deleted on logout
- **Disabled** (default): Local data is preserved for next login

**Benefits**:
- Privacy: Remove personal data when logging out
- Flexibility: Keep data for quick re-login
- User control: Let users decide their preference

**UI Location**: Settings → Logout → Clear data on logout

## Core Data Stack Methods

### Migration Support Methods

#### `isMigrationNeeded() -> Bool`
Checks if the current store requires migration by comparing store metadata with the current model.

#### `getStoreSize() -> Int64?`
Returns the size of the persistent store file in bytes. Useful for displaying storage usage.

#### `destroyAndRecreateStore() throws`
Completely removes the persistent store and creates a new one. Used for re-sync scenarios.

### Data Cleanup Methods

#### `clearAllData() throws`
Deletes all data from all entities while keeping the store intact.

#### `deleteAllUserAnime() throws`
Deletes all user anime list entries.

#### `deleteAllAnime() throws`
Deletes all cached anime metadata.

#### `deleteAllSyncQueue() throws`
Deletes all pending sync operations.

## Requirements Satisfied

### Requirement 6.5
**IF local data becomes corrupted THEN the system SHALL provide an option to re-sync from AniList**

✅ Implemented via:
- Automatic migration failure recovery
- Manual "Re-sync from AniList" option in Settings
- `destroyAndRecreateStore()` method

### Requirement 6.6
**WHEN the user logs out THEN the system SHALL optionally clear local data or keep it for the next login**

✅ Implemented via:
- "Clear data on logout" toggle in Settings
- Conditional data cleanup in `logout()` method
- User preference preserved between sessions

## Usage Examples

### For Developers

#### Performing a Manual Re-sync
```swift
let viewModel = SettingsViewModel(
    authenticationService: authService,
    coreDataStack: coreDataStack,
    syncService: syncService
)

// Trigger re-sync
await viewModel.performResync()
```

#### Clearing Data on Logout
```swift
// Enable clear data on logout
viewModel.clearDataOnLogout = true

// Logout (will clear data)
viewModel.logout()
```

#### Checking Migration Status
```swift
let coreDataStack = CoreDataStack.shared

if coreDataStack.isMigrationNeeded() {
    print("Migration will be performed on next load")
}

if let size = coreDataStack.getStoreSize() {
    print("Store size: \(size) bytes")
}
```

### For Users

#### Re-syncing Data
1. Open Settings
2. Scroll to "Data Management" section
3. Click "Re-sync from AniList"
4. Confirm the action
5. Wait for sync to complete

#### Clearing Local Data
1. Open Settings
2. Scroll to "Data Management" section
3. Click "Clear Local Data"
4. Confirm the action

#### Configuring Logout Behavior
1. Open Settings
2. Scroll to "Logout" section
3. Toggle "Clear data on logout" as desired
4. Click "Logout" when ready

## Error Handling

All data management operations include comprehensive error handling:

- **Migration Failures**: Automatically recovered by recreating store
- **Re-sync Errors**: Displayed to user with error message
- **Clear Data Errors**: Displayed to user with error message
- **Network Errors**: Handled gracefully during re-sync

## Testing Recommendations

### Manual Testing
- [ ] Test automatic migration with schema changes
- [ ] Test migration failure recovery
- [ ] Test re-sync from AniList
- [ ] Test clear local data
- [ ] Test logout with data clearing enabled
- [ ] Test logout with data clearing disabled

### Unit Testing
- [ ] Test `isMigrationNeeded()` with different store states
- [ ] Test `destroyAndRecreateStore()` success and failure
- [ ] Test `clearAllData()` removes all entities
- [ ] Test logout with `clearDataOnLogout` enabled/disabled

## Future Enhancements

### Potential Improvements
1. **Selective Data Cleanup**: Allow users to clear specific data types
2. **Backup Before Re-sync**: Create backup before destroying store
3. **Migration Progress**: Show progress during large migrations
4. **Storage Usage Display**: Show detailed storage breakdown
5. **Export/Import**: Allow users to export/import their data
6. **Scheduled Cleanup**: Automatic cleanup of old cached data

### Advanced Migration Support
1. **Custom Mapping Models**: For complex schema changes
2. **Progressive Migration**: Support multi-version migrations
3. **Migration Validation**: Verify data integrity after migration
4. **Rollback Support**: Ability to rollback failed migrations

## Conclusion

The data migration and cleanup implementation provides:
- ✅ Automatic lightweight migration for schema changes
- ✅ Automatic recovery from migration failures
- ✅ Manual re-sync option for corrupted data
- ✅ Optional data cleanup on logout
- ✅ User control over data management
- ✅ Comprehensive error handling
- ✅ Clear user feedback

This ensures a robust and user-friendly data management experience in AniLedger.
