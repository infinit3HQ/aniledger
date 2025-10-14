//
//  LibraryView.swift
//  AniLedger
//
//  Main library view with status tabs for managing anime lists
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel
    
    let animeService: AnimeServiceProtocol
    let syncService: SyncServiceProtocol
    
    @State private var selectedStatus: AnimeStatus = .watching
    @State private var selectedAnime: UserAnime?
    @State private var showAnimeDetail = false
    @State private var draggedAnime: UserAnime?
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Tabs
            statusTabBar
            
            Divider()
            
            // Content Area
            ZStack {
                if viewModel.isLoading && currentList.isEmpty {
                    skeletonLoadingView
                } else if let error = viewModel.error {
                    errorView(error: error)
                } else if currentList.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    viewModel.sync()
                }) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showAnimeDetail) {
            if let anime = selectedAnime {
                AnimeDetailView(viewModel: createDetailViewModel(for: anime))
            }
        }
        .onAppear {
            if viewModel.watchingList.isEmpty &&
               viewModel.completedList.isEmpty &&
               viewModel.planToWatchList.isEmpty &&
               viewModel.onHoldList.isEmpty &&
               viewModel.droppedList.isEmpty {
                viewModel.loadLists()
            }
        }
    }
    
    // MARK: - Status Tab Bar
    
    private var statusTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AnimeStatus.allCases, id: \.self) { status in
                statusTab(for: status)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func statusTab(for status: AnimeStatus) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedStatus = status
            }
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: statusIcon(for: status))
                        .font(.caption)
                    
                    Text(status.displayName)
                        .font(.subheadline)
                        .fontWeight(selectedStatus == status ? .semibold : .regular)
                    
                    Text("\(listCount(for: status))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                        )
                }
                .foregroundColor(selectedStatus == status ? .accentColor : .secondary)
                
                Rectangle()
                    .fill(selectedStatus == status ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(currentList) { anime in
                    AnimeListItemView(userAnime: anime)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticFeedback.selection.trigger()
                            selectedAnime = anime
                            showAnimeDetail = true
                        }
                        .contextMenu {
                            contextMenuItems(for: anime)
                        }
                        .onDrag {
                            self.draggedAnime = anime
                            return NSItemProvider(object: String(anime.id) as NSString)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding()
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentList.count)
        }
        .refreshable {
            viewModel.sync()
        }
        .onDrop(of: [.text], delegate: AnimeDropDelegate(
            status: selectedStatus,
            draggedAnime: $draggedAnime,
            viewModel: viewModel
        ))
    }
    
    // MARK: - Skeleton Loading View
    
    private var skeletonLoadingView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    AnimeListItemSkeleton()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        Group {
            switch selectedStatus {
            case .watching:
                EmptyStateView.emptyWatchingList()
            case .completed:
                EmptyStateView.emptyCompletedList()
            case .planToWatch:
                EmptyStateView.emptyPlanToWatchList()
            case .onHold:
                EmptyStateView.emptyOnHoldList()
            case .dropped:
                EmptyStateView.emptyDroppedList()
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(error: KiroError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Error Loading Library")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                viewModel.loadLists()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func contextMenuItems(for anime: UserAnime) -> some View {
        Button(action: {
            selectedAnime = anime
            showAnimeDetail = true
        }) {
            Label("View Details", systemImage: "info.circle")
        }
        
        Divider()
        
        Menu("Move to...") {
            ForEach(AnimeStatus.allCases.filter { $0 != anime.status }, id: \.self) { status in
                Button(action: {
                    viewModel.moveAnime(anime, to: status)
                }) {
                    Label(status.displayName, systemImage: statusIcon(for: status))
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            viewModel.deleteAnime(anime)
        }) {
            Label("Remove from Library", systemImage: "trash")
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentList: [UserAnime] {
        switch selectedStatus {
        case .watching: return viewModel.watchingList
        case .completed: return viewModel.completedList
        case .planToWatch: return viewModel.planToWatchList
        case .onHold: return viewModel.onHoldList
        case .dropped: return viewModel.droppedList
        }
    }
    
    private func listCount(for status: AnimeStatus) -> Int {
        switch status {
        case .watching: return viewModel.watchingList.count
        case .completed: return viewModel.completedList.count
        case .planToWatch: return viewModel.planToWatchList.count
        case .onHold: return viewModel.onHoldList.count
        case .dropped: return viewModel.droppedList.count
        }
    }
    
    // MARK: - Helper Functions
    
    private func statusIcon(for status: AnimeStatus) -> String {
        switch status {
        case .watching: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .planToWatch: return "calendar.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "xmark.circle.fill"
        }
    }
    
    private func createDetailViewModel(for userAnime: UserAnime) -> AnimeDetailViewModel {
        AnimeDetailViewModel(
            anime: userAnime.anime,
            userAnime: userAnime,
            animeService: animeService,
            syncService: syncService
        )
    }
}

// MARK: - Anime List Item View

struct AnimeListItemView: View {
    let userAnime: UserAnime
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover Image
            AsyncImageView(
                url: userAnime.anime.coverImage.medium,
                width: 60,
                height: 84
            )
            .cornerRadius(6)
            .shadow(radius: isHovered ? 4 : 2)
            
            // Anime Info
            VStack(alignment: .leading, spacing: 6) {
                Text(userAnime.anime.title.preferred)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // Progress
                    ProgressIndicatorView(
                        current: userAnime.progress,
                        total: userAnime.anime.episodes,
                        compact: true
                    )
                    
                    // Format
                    Text(formatDisplayName(userAnime.anime.format))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Score (if available)
                    if let score = userAnime.score, score > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", score))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Genres
                if !userAnime.anime.genres.isEmpty {
                    Text(userAnime.anime.genres.prefix(3).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Sync indicator
            if userAnime.needsSync {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .help("Pending sync")
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1.0 : 0.5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.1 : 0), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatDisplayName(_ format: AnimeFormat) -> String {
        switch format {
        case .tv: return "TV"
        case .tvShort: return "TV Short"
        case .movie: return "Movie"
        case .special: return "Special"
        case .ova: return "OVA"
        case .ona: return "ONA"
        case .music: return "Music"
        }
    }
}

// MARK: - Drop Delegate

struct AnimeDropDelegate: DropDelegate {
    let status: AnimeStatus
    @Binding var draggedAnime: UserAnime?
    let viewModel: LibraryViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        guard let anime = draggedAnime else { return false }
        
        if anime.status != status {
            viewModel.moveAnime(anime, to: status)
        }
        
        draggedAnime = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Preview

#Preview {
    let mockAnimeService = MockAnimeService()
    let mockSyncService = MockSyncService()
    
    let viewModel = LibraryViewModel(
        animeService: mockAnimeService,
        syncService: mockSyncService
    )
    
    // Populate with sample data
    viewModel.watchingList = [
        UserAnime(
            id: 1,
            anime: Anime(
                id: 1,
                title: AnimeTitle(romaji: "Kimetsu no Yaiba", english: "Demon Slayer", native: "鬼滅の刃"),
                coverImage: CoverImage(
                    large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101922-PEn1CTc93blC.jpg",
                    medium: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx101922-PEn1CTc93blC.jpg"
                ),
                episodes: 26,
                format: .tv,
                genres: ["Action", "Fantasy"],
                synopsis: "A boy fights demons.",
                siteUrl: "https://anilist.co/anime/101922"
            ),
            status: .watching,
            progress: 5,
            score: 9.5,
            sortOrder: 0,
            needsSync: false,
            lastModified: Date()
        )
    ]
    
    return NavigationStack {
        LibraryView(
            viewModel: viewModel,
            animeService: mockAnimeService,
            syncService: mockSyncService
        )
    }
}

// MARK: - Mock Services

private class MockAnimeService: AnimeServiceProtocol {
    func addAnimeToLibrary(_ anime: Anime, status: AnimeStatus, progress: Int, score: Double?) throws -> UserAnime {
        UserAnime(
            id: anime.id,
            anime: anime,
            status: status,
            progress: progress,
            score: score,
            sortOrder: 0,
            needsSync: true,
            lastModified: Date()
        )
    }
    
    func updateAnimeProgress(_ userAnimeId: Int, progress: Int) throws -> UserAnime {
        fatalError("Not implemented for preview")
    }
    
    func updateAnimeStatus(_ userAnimeId: Int, status: AnimeStatus) throws -> UserAnime {
        fatalError("Not implemented for preview")
    }
    
    func updateAnimeScore(_ userAnimeId: Int, score: Double?) throws -> UserAnime {
        fatalError("Not implemented for preview")
    }
    
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws {
        // No-op for preview
    }
    
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime] {
        []
    }
    
    func fetchAllUserAnime() throws -> [UserAnime] {
        []
    }
    
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime {
        fatalError("Not implemented for preview")
    }
    
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws {
        // No-op for preview
    }
    
    func getUserAnime(byId id: Int) throws -> UserAnime? {
        nil
    }
    
    func getUserAnime(byAnimeId animeId: Int) throws -> UserAnime? {
        nil
    }
}

private class MockSyncService: SyncServiceProtocol {
    func syncAll() async throws {
        // No-op for preview
    }
    
    func syncUserLists() async throws {
        // No-op for preview
    }
    
    func processSyncQueue() async throws {
        // No-op for preview
    }
    
    func queueOperation(_ operation: SyncOperation) {
        // No-op for preview
    }
}
