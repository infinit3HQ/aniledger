//
//  AboutView.swift
//  AniLedger
//
//  About view displaying app information
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showReleaseNotes = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.top, 30)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Version Info
                    versionSection
                    
                    Divider()
                    
                    // Description
                    descriptionSection
                    
                    Divider()
                    
                    // Features
                    featuresSection
                    
                    Divider()
                    
                    // Links
                    linksSection
                    
                    Divider()
                    
                    // License
                    licenseSection
                    
                    Divider()
                    
                    // System Info
                    systemInfoSection
                }
                .padding(24)
            }
            
            // Footer
            footerSection
                .padding(.vertical, 16)
        }
        .frame(width: 500, height: 600)
        .sheet(isPresented: $showReleaseNotes) {
            ReleaseNotesView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // App Icon (placeholder - replace with actual icon)
            Image(systemName: "books.vertical.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text(AppInfo.appName)
                .font(.system(size: 28, weight: .bold))
            
            Text("Version \(AppInfo.fullVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Version Section
    
    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Version Information")
            
            InfoRow(label: "Version", value: AppInfo.version)
            InfoRow(label: "Build", value: AppInfo.buildNumber)
            InfoRow(label: "Bundle ID", value: AppInfo.bundleIdentifier)
            
            Button {
                showReleaseNotes = true
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("View Release Notes")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "About")
            
            Text(AppInfo.fullDescription)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Features")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 8) {
                ForEach(AppInfo.features, id: \.self) { feature in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    // MARK: - Links Section
    
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Links")
            
            LinkButton(title: "GitHub Repository", url: AppInfo.repositoryURL, icon: "link.circle.fill")
            LinkButton(title: "AniList Website", url: AppInfo.aniListURL, icon: "globe")
            LinkButton(title: "API Documentation", url: AppInfo.apiDocumentationURL, icon: "doc.text.fill")
            LinkButton(title: "Report Issues", url: AppInfo.supportURL, icon: "exclamationmark.bubble.fill")
        }
    }
    
    // MARK: - License Section
    
    private var licenseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "License")
            
            Text(AppInfo.licenseType)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(AppInfo.licenseSummary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - System Info Section
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "System Information")
            
            InfoRow(label: "macOS Version", value: AppInfo.currentOSVersion)
            InfoRow(label: "Minimum Required", value: "macOS \(AppInfo.minimumOSVersion)+")
            InfoRow(label: "Category", value: AppInfo.categoryType.replacingOccurrences(of: "public.app-category.", with: "").capitalized)
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text(AppInfo.copyright)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Supporting Views

private struct SectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

private struct LinkButton: View {
    let title: String
    let url: URL
    let icon: String
    
    var body: some View {
        Button(action: {
            NSWorkspace.shared.open(url)
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    AboutView()
}
