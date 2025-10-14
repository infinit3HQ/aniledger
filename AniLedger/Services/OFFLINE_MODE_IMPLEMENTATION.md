# Offline Mode Implementation

## Overview

AniLedger supports full offline functionality, allowing users to view and edit their anime library even when disconnected from the internet. All changes made offline are automatically synced when the connection is restored.

## Components

### NetworkMonitor

**Location:** `AniLedger/Services/NetworkMonitor.swift`

A singleton service that monitors network connectivity using Apple's `NWPathMonitor` framework.

**Features:**
- Real-time network status monitoring
- Connection type detection (WiFi, Cellular, etc.)
- Automatic notification when connection is restored
- Published properties for SwiftUI integration

**Usage:**
```swift
// Access the shared instance
let isOnline = NetworkMonitor.shared.isConnected

// Observe in SwiftUI
@ObservedObject var networkMonitor = NetworkMonitor.shared
```

### OfflineIndicatorView

**Location:** `AniLedger/Views/OfflineIndicatorView.swift`

A banner component that displays when the device is offline.

**Features:**
- Automatically shows/hides based on network status
- Smooth animations for appearance/disappearance
- Informative message about offline mode
- Orange color scheme for visibility

**Integration:**
The indicator is integrated into `ContentView` and appears at the top of the main navigation view.

### SyncService Updates

**Location:** `AniLedger/Services/SyncService.swift`

The SyncService has been enhanced to handle offline mode:

**Features:**
1. **Network Connectivity Checks:** All sync operations check network status before attempting API calls
2. **Automatic Queue Processing:** Listens for network restoration notifications and automatically processes pending changes
3. **Graceful Degradation:** Silently returns when offline instead of throwing errors

**Behavior:**
- `syncAll()`: Throws error if offline (used during login)
- `syncUserLists()`: Throws error if offline (used for manual sync)
- `processSyncQueue()`: Silently returns if offline (used after local changes)

### AnimeService

**Location:** `AniLedger/Services/AnimeService.swift`

The AnimeService already supports offline mode by:
- Setting `needsSync = true` on all local changes
- Storing all changes in Core Data immediately
- Not requiring network connectivity for local operations

## How It Works

### Making Changes Offline

1. User makes a change (e.g., updates progress, changes status)
2. Change is saved to Core Data with `needsSync = true`
3. SyncService attempts to process sync queue
4. If offline, the operation is silently skipped
5. Change remains in local database with sync flag

### Automatic Sync on Reconnection

1. NetworkMonitor detects connection restoration
2. Posts `networkConnectionRestored` notification
3. SyncService receives notification
4. Automatically processes sync queue
5. All pending changes are synced to AniList
6. `needsSync` flags are cleared on successful sync

### User Experience

**When Offline:**
- Orange banner appears at top of screen
- All local operations work normally
- Changes are saved locally
- No error messages for sync failures

**When Connection Restored:**
- Banner disappears
- Sync queue automatically processes
- User sees their changes reflected on AniList
- No manual intervention required

## Data Flow

```
User Action (Offline)
    ↓
AnimeService (Save to Core Data)
    ↓
Set needsSync = true
    ↓
SyncService.processSyncQueue()
    ↓
Check NetworkMonitor.isConnected
    ↓
If Offline: Return silently
    ↓
[Wait for connection]
    ↓
NetworkMonitor detects connection
    ↓
Post networkConnectionRestored notification
    ↓
SyncService receives notification
    ↓
Process sync queue automatically
    ↓
Send changes to AniList API
    ↓
Clear needsSync flags
```

## Testing Offline Mode

### Manual Testing

1. **Disconnect from network:**
   - Turn off WiFi
   - Disconnect ethernet
   - Or use Network Link Conditioner

2. **Verify offline indicator appears:**
   - Orange banner should show at top

3. **Make changes:**
   - Update anime progress
   - Change anime status
   - Add anime to library
   - Remove anime from library

4. **Verify local changes persist:**
   - Changes should be visible immediately
   - No error messages should appear

5. **Reconnect to network:**
   - Turn WiFi back on
   - Banner should disappear

6. **Verify automatic sync:**
   - Check AniList website
   - Changes should appear within seconds

### Network Link Conditioner

For more controlled testing, use Apple's Network Link Conditioner:

1. Download from Apple Developer Tools
2. Install on macOS
3. Enable "100% Loss" profile to simulate offline
4. Test offline functionality
5. Disable to simulate reconnection

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

**Requirement 6.3:** "WHEN the user is offline THEN the system SHALL allow viewing and modifying locally stored anime data"
- ✅ All local operations work offline
- ✅ Changes are saved to Core Data
- ✅ No network errors shown to user

**Requirement 6.4:** "WHEN the user makes changes offline THEN the system SHALL queue changes for sync when connection is restored"
- ✅ Changes marked with needsSync flag
- ✅ Automatic sync queue processing on reconnection
- ✅ No manual intervention required

## Future Enhancements

Potential improvements for offline mode:

1. **Sync Queue UI:** Show pending changes count in settings
2. **Manual Retry:** Allow user to manually trigger sync
3. **Conflict Resolution UI:** Show conflicts to user for manual resolution
4. **Offline Indicator Details:** Show last sync time
5. **Bandwidth Optimization:** Batch sync operations when reconnecting
