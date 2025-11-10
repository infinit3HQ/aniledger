# App Information Management

This document describes the comprehensive information management system implemented in AniLedger.

## Overview

AniLedger now includes a robust information management system that centralizes app metadata, version tracking, and user-facing information displays.

## Components

### 1. Info.plist Configuration

**Location**: `AniLedger/Info.plist`

The Info.plist now includes complete app metadata:

#### App Identity
- **CFBundleIdentifier**: `com.aniledger`
- **CFBundleName**: `AniLedger`
- **CFBundleDisplayName**: `AniLedger`
- **CFBundleExecutable**: Dynamic executable name
- **CFBundlePackageType**: `APPL`

#### Version Information
- **CFBundleShortVersionString**: `0.2.0` (user-facing version)
- **CFBundleVersion**: `1` (build number)

#### App Metadata
- **NSHumanReadableCopyright**: Copyright notice
- **LSApplicationCategoryType**: `public.app-category.entertainment`
- **LSMinimumSystemVersion**: `12.0` (macOS Monterey)

#### Privacy & Security
- **NSUserNotificationsUsageDescription**: Notification permission explanation
- **NSAppTransportSecurity**: Secure network configuration for AniList API
- **NSHighResolutionCapable**: Retina display support

#### URL Schemes
- **aniledger://**: OAuth callback URL scheme

### 2. AppInfo Utility

**Location**: `AniLedger/Utilities/AppInfo.swift`

A centralized utility struct that provides programmatic access to app information:

#### Properties

**Identity**
```swift
AppInfo.bundleIdentifier  // "com.aniledger"
AppInfo.appName           // "AniLedger"
```

**Version**
```swift
AppInfo.version           // "0.2.0"
AppInfo.buildNumber       // "1"
AppInfo.fullVersion       // "0.2.0 (1)"
```

**System**
```swift
AppInfo.minimumOSVersion  // "12.0"
AppInfo.currentOSVersion  // Current macOS version
AppInfo.categoryType      // App category
```

**URLs**
```swift
AppInfo.repositoryURL         // GitHub repo
AppInfo.aniListURL           // AniList website
AppInfo.apiDocumentationURL  // API docs
AppInfo.supportURL           // Issues page
```

**Description**
```swift
AppInfo.shortDescription  // Brief description
AppInfo.fullDescription   // Detailed description
AppInfo.features          // Array of features
```

**License**
```swift
AppInfo.licenseType       // "Non-Commercial Open Source"
AppInfo.licenseSummary    // License summary
```

**Developer**
```swift
AppInfo.developerName     // "AniLedger"
AppInfo.copyright         // Copyright notice
```

#### Methods

```swift
// Check build mode
AppInfo.isDebugMode       // true in debug builds
AppInfo.isPreviewMode     // true in Xcode previews

// Get formatted info
AppInfo.formattedInfo()   // Multi-line formatted string
AppInfo.debugInfo()       // Dictionary for debugging
```

### 3. About View

**Location**: `AniLedger/Views/AboutView.swift`

A comprehensive About view displaying app information:

#### Sections

1. **Header**
   - App icon (placeholder)
   - App name
   - Version number

2. **Version Information**
   - Version and build number
   - Bundle identifier
   - Link to release notes

3. **Description**
   - Full app description

4. **Features**
   - Grid layout of key features
   - Checkmark indicators

5. **Links**
   - GitHub repository
   - AniList website
   - API documentation
   - Issue reporting

6. **License**
   - License type
   - License summary

7. **System Information**
   - Current macOS version
   - Minimum required version
   - App category
   - Debug mode indicator

#### Access

The About view is accessible from:
- Settings → About AniLedger

### 4. Release Notes View

**Location**: `AniLedger/Views/ReleaseNotesView.swift`

A dedicated view for displaying version history and release notes:

#### Features

- **Version Cards**: Each release displayed in a card format
- **Current Version Badge**: Highlights the current version
- **Categorized Changes**:
  - New Features (blue, sparkles icon)
  - Improvements (green, arrow up icon)
  - Bug Fixes (orange, wrench icon)
- **Scrollable History**: View all past releases

#### Release Note Model

```swift
struct ReleaseNote {
    let version: String
    let date: String
    let features: [String]
    let improvements: [String]
    let bugFixes: [String]
}
```

#### Access

The Release Notes view is accessible from:
- About View → View Release Notes button

### 5. Settings Integration

**Location**: `AniLedger/Views/SettingsView.swift`

The Settings view now includes an About section:

```swift
Section {
    Button {
        showAbout = true
    } label: {
        HStack {
            Image(systemName: "info.circle")
            VStack(alignment: .leading) {
                Text("About AniLedger")
                Text("Version \(AppInfo.version) (\(AppInfo.buildNumber))")
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
    }
} header: {
    Text("About")
}
```

## Usage

### Displaying App Version

```swift
// In any view
Text("Version \(AppInfo.version)")

// Full version with build
Text(AppInfo.fullVersion)
```

### Opening External Links

```swift
// Open GitHub repository
NSWorkspace.shared.open(AppInfo.repositoryURL)

// Open support page
NSWorkspace.shared.open(AppInfo.supportURL)
```

### Checking System Requirements

```swift
// Check if running on supported OS
let currentVersion = AppInfo.currentOSVersion
let minimumVersion = AppInfo.minimumOSVersion

// Display in UI
Text("Requires macOS \(AppInfo.minimumOSVersion) or later")
```

### Debug Information

```swift
// Get debug info dictionary
let debugInfo = AppInfo.debugInfo()
print(debugInfo)

// Check debug mode
if AppInfo.isDebugMode {
    // Show debug-only features
}
```

## Updating Version Information

### For New Releases

1. **Update Info.plist**:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>0.3.0</string>
   <key>CFBundleVersion</key>
   <string>1</string>
   ```

2. **Add Release Notes**:
   ```swift
   // In ReleaseNotesView.swift
   static let allReleases: [ReleaseNote] = [
       ReleaseNote(
           version: "0.3.0",
           date: "December 2025",
           features: ["New feature 1", "New feature 2"],
           improvements: ["Improvement 1"],
           bugFixes: ["Fix 1"]
       ),
       // ... existing releases
   ]
   ```

3. **Update README.md** (if needed):
   - Update version requirements
   - Add new features to feature list
   - Update screenshots if UI changed

### Build Number Increment

Increment the build number for each build:
```xml
<key>CFBundleVersion</key>
<string>2</string>  <!-- Increment for each build -->
```

## Best Practices

1. **Version Numbering**:
   - Use semantic versioning (MAJOR.MINOR.PATCH)
   - Increment MAJOR for breaking changes
   - Increment MINOR for new features
   - Increment PATCH for bug fixes

2. **Release Notes**:
   - Keep entries concise and user-friendly
   - Group changes by category (features, improvements, fixes)
   - Use present tense ("Add" not "Added")
   - Focus on user-visible changes

3. **Info.plist**:
   - Keep bundle identifier consistent
   - Update copyright year annually
   - Maintain accurate minimum OS version

4. **AppInfo Utility**:
   - Add new properties as needed
   - Keep URLs up to date
   - Update descriptions when features change

## Security Considerations

- **Bundle Identifier**: Never change after release (breaks updates)
- **URL Schemes**: Ensure OAuth callback matches AniList settings
- **Network Security**: ATS configuration restricts to HTTPS only
- **Privacy Descriptions**: Keep notification usage description accurate

## Testing

### Manual Testing

1. **About View**:
   - Open Settings → About AniLedger
   - Verify all information displays correctly
   - Test all external links
   - Check release notes viewer

2. **Version Display**:
   - Verify version matches Info.plist
   - Check build number accuracy
   - Confirm current version badge in release notes

3. **System Info**:
   - Verify macOS version detection
   - Check minimum version display
   - Confirm debug mode indicator (in debug builds)

### Automated Testing

```swift
// Test AppInfo utility
func testAppInfo() {
    XCTAssertEqual(AppInfo.bundleIdentifier, "com.aniledger")
    XCTAssertFalse(AppInfo.version.isEmpty)
    XCTAssertFalse(AppInfo.buildNumber.isEmpty)
    XCTAssertNotNil(AppInfo.repositoryURL)
}
```

## Future Enhancements

Potential improvements to the information management system:

1. **Automatic Update Checking**:
   - Check GitHub releases for new versions
   - Notify users of available updates

2. **In-App Changelog**:
   - Show release notes on first launch after update
   - "What's New" modal

3. **Crash Reporting**:
   - Optional crash report submission
   - Include app info in reports

4. **Analytics** (Optional):
   - Usage statistics (with user consent)
   - Feature adoption tracking

5. **Localization**:
   - Translate app information
   - Localized release notes

## Related Files

- `AniLedger/Info.plist` - App metadata
- `AniLedger/Utilities/AppInfo.swift` - Information utility
- `AniLedger/Views/AboutView.swift` - About screen
- `AniLedger/Views/ReleaseNotesView.swift` - Release notes
- `AniLedger/Views/SettingsView.swift` - Settings integration
- `README.md` - User-facing documentation
- `RELEASES/` - Release documentation

## Support

For questions or issues related to app information management:
- Open an issue on GitHub
- Check the README.md troubleshooting section
- Review this documentation
