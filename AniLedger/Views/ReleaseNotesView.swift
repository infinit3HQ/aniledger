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
