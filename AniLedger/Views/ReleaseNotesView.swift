//
//  ReleaseNotesView.swift
//  AniLedger
//
//  Release notes and version history view
//

import SwiftUI

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Release Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Release notes list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(ReleaseNote.allReleases, id: \.version) { release in
                        ReleaseNoteCard(release: release)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Release Note Card

private struct ReleaseNoteCard: View {
    let release: ReleaseNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Version header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Version \(release.version)")
                            .font(.headline)
                        
                        if release.version == AppInfo.version {
                            Text("Current")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(release.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Features
            if !release.features.isEmpty {
                ChangeSection(title: "New Features", items: release.features, icon: "sparkles", color: .blue)
            }
            
            // Improvements
            if !release.improvements.isEmpty {
                ChangeSection(title: "Improvements", items: release.improvements, icon: "arrow.up.circle", color: .green)
            }
            
            // Bug Fixes
            if !release.bugFixes.isEmpty {
                ChangeSection(title: "Bug Fixes", items: release.bugFixes, icon: "wrench.and.screwdriver", color: .orange)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Change Section

private struct ChangeSection: View {
    let title: String
    let items: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

// MARK: - Release Note Model

struct ReleaseNote {
    let version: String
    let date: String
    let features: [String]
    let improvements: [String]
    let bugFixes: [String]
    
    static let allReleases: [ReleaseNote] = [
        ReleaseNote(
            version: "0.5.1",
            date: "October 31, 2026",
            features: [],
            improvements: [
                "Seasons header: the season picker, year buttons and Current button now share one style and size",
                "Discover filters: Genres and Format use the standard macOS menu button and show the number of active filters",
                "Library toolbar: the Sort button is now the same size as the other toolbar buttons"
            ],
            bugFixes: [
                "Fixed the anime detail sheet resetting progress and closing the 'Complete Anime?' prompt when you increment the last episode",
                "Fixed the year showing as '2,026' in the Seasons header",
                "Fixed cover images not being cached on disk, so they no longer download again on every launch"
            ]
        ),
        ReleaseNote(
            version: "0.5.0",
            date: "October 31, 2026",
            features: [
                "Simpler, working login: AniLedger now signs in with AniList's implicit grant, so the downloaded app logs in without any extra setup",
                "Library updates by itself: changes from the detail sheet, Search, Discover and background syncs appear without pressing Sync",
                "Non-blocking sync errors: a failed sync shows a small banner with Retry and Dismiss instead of hiding your library"
            ],
            improvements: [
                "Expired or revoked AniList logins now return you to the login screen instead of failing on every screen",
                "Launching offline no longer causes 'User not authenticated' errors once you're back online",
                "Sync requests now run one after another, so pressing Sync never silently does nothing",
                "Universal build for Apple Silicon and Intel Macs"
            ],
            bugFixes: [
                "Fixed offline edits overwriting each other (for example, a score change erasing a progress change)",
                "Fixed entries getting stuck and never updating from AniList after repeated sync failures",
                "Fixed deleted entries coming back after a sync",
                "Fixed 'User anime not found' errors when acting on an entry right after a sync",
                "Fixed the library error screen's Retry button doing nothing",
                "Fixed 'Clear data' leaving deleted items on screen"
            ]
        ),
        ReleaseNote(
            version: "0.4.0",
            date: "August 27, 2026",
            features: [
                "Interactive Anime Scoring: Score and rate anime directly from the Anime Detail sheet with instant AniList remote sync",
                "In-Library Search & Sorting: Search within your library and sort lists by Title (A-Z, Z-A), Highest Score, or Most Progress",
                "Real-Time Library Badges: Visual status pills (Watching, Completed, Dropped, Plan to Watch, On Hold) displayed across Search results, Discover, and Seasonal anime cards",
                "Upcoming Year Seasons: Extended seasonal browser to explore announced anime for the upcoming calendar year"
            ],
            improvements: [
                "Periodic Auto-Sync: 15-minute background auto-sync timer keeping your library fresh and synced with AniList",
                "Architecture & Lifecycle: Retained ViewModels in StateObjects to prevent redundant state re-instantiations",
                "Throttled Airing Schedule Checks: Request throttling and error isolation to avoid rate-limiting and query failures",
                "Comprehensive Test Coverage: Added unit test suites for ViewModels, Services, and Notifications"
            ],
            bugFixes: [
                "Fixed remote deletion sync so deleted anime are removed on AniList without resurrecting",
                "Fixed Discover and Search 'Add to Library' actions to automatically queue and push AniList sync",
                "Fixed Search and Discover detail views to properly detect existing library anime instead of showing 'Add to Library'",
                "Fixed Core Data memory store recreation to prevent stale faulted objects"
            ]
        ),
        ReleaseNote(
            version: "0.3.0",
            date: "November 11, 2025",
            features: [
                "Airing Notifications: Get timely alerts for upcoming anime episodes",
                "AiringScheduleService and NotificationService for proactive episode notifications",
                "Banner image support for anime entities for a richer visual experience",
                "Comprehensive app information management system (AppInfo, AboutView, ReleaseNotesView)",
                "Centralized app metadata and version tracking"
            ],
            improvements: [
                "More detailed error types, improved localization, and clearer user feedback",
                "Updated SearchView layout and frame configuration",
                "Redesigned AnimeDetailView close button design and interaction",
                "Consistent loading view sizing and frame consistency",
                "Thread-safe sync state management with better logging",
                "Improved error handling in auto-sync service",
                "Enhanced sync reliability and error reporting"
            ],
            bugFixes: []
        ),
        ReleaseNote(
            version: "0.2.0",
            date: "October 31, 2025",
            features: [
                "Filter and sort controls for Discover and Search (season, format, score)",
                "Improved search ranking and result stability",
                "Offline edits now batch and sync more reliably when connection is restored",
                "Clearer offline indicator and sync status"
            ],
            improvements: [
                "Redesigned sync flow to better handle intermittent network conditions",
                "Fewer duplicate entries after re-sync and improved conflict resolution for local edits",
                "Faster library load times for large libraries",
                "Reduced memory use during image-heavy screens",
                "Better keyboard navigation and focus behavior across list and detail views",
                "Accessibility labels improved for VoiceOver users",
                "Improved image caching behavior to reduce memory spikes",
                "Hardened token refresh and Keychain handling to avoid stale auth and improve retry logic"
            ],
            bugFixes: [
                "Fixed issue where progress could reset after a failed sync",
                "Fixed crash when opening some anime detail pages with missing data",
                "Resolved layout glitch in dark mode for the library cards",
                "Fixed crash in AnimeDetail when cover image metadata was missing",
                "Fixed several visual layout bugs across macOS window sizes"
            ]
        ),
        ReleaseNote(
            version: "0.1.0",
            date: "October 19, 2025",
            features: [
                "Library Management: Organize anime into Watching, Completed, Plan to Watch, On Hold, and Dropped lists",
                "AniList Sync: Seamlessly sync your progress with AniList.co",
                "Discover & Search: Browse seasonal anime, trending titles, and search for specific anime",
                "Seasonal Browser: Explore anime by season (Winter, Spring, Summer, Fall) and year",
                "Progress Tracking: Update episode progress with visual progress indicators",
                "Offline Support: View and edit your library offline with automatic sync when reconnected",
                "Network Monitoring: Visual offline indicator when disconnected",
                "Native macOS UI: Beautiful SwiftUI interface with light/dark mode support",
                "Secure Authentication: OAuth2 flow with secure Keychain token storage",
                "Image Caching: Efficient image loading and caching for smooth performance",
                "Data Management: Re-sync from AniList, clear local data, and automatic migration support"
            ],
            improvements: [],
            bugFixes: []
        )
    ]
}

// MARK: - Preview

#Preview {
    ReleaseNotesView()
}
