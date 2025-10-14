//
//  AnimeDetailView.swift
//  AniLedger
//
//  Detail view for displaying anime information and managing progress
//

import SwiftUI

struct AnimeDetailView: View {
    @ObservedObject var viewModel: AnimeDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showStatusPicker = false
    @State private var showAddToLibrarySheet = false
    @State private var selectedStatus: AnimeStatus = .watching
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Cover Image Header
                coverImageSection
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Content Section
                VStack(alignment: .leading, spacing: 24) {
                    // Title Section
                    titleSection
                    
                    // Progress and Status Controls (if in library)
                    if viewModel.isInLibrary {
                        progressSection
                        statusSection
                    }
                    
                    // Synopsis
                    synopsisSection
                    
                    // Metadata (Episode count, Format)
                    metadataSection
                    
                    // Genres
                    genresSection
                    
                    // User Score (if available)
                    if let score = viewModel.userAnime?.score, score > 0 {
                        scoreSection(score: score)
                    }
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isInLibrary)
        .alert("Complete Anime?", isPresented: $viewModel.showCompletionPrompt) {
            Button("Move to Completed") {
                Task {
                    await viewModel.handleCompletion(moveToCompleted: true)
                }
            }
            Button("Keep Watching", role: .cancel) {
                Task {
                    await viewModel.handleCompletion(moveToCompleted: false)
                }
            }
        } message: {
            Text("You've reached the final episode. Would you like to move this anime to your Completed list?")
        }
        .alert("Remove from Library?", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.removeFromLibrary()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \"\(viewModel.anime.title.preferred)\" from your library?")
        }
        .sheet(isPresented: $showAddToLibrarySheet) {
            addToLibrarySheet
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Cover Image Section
    
    private var coverImageSection: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImageView(
                url: viewModel.anime.coverImage.large,
                width: 600,
                height: 300
            )
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color(nsColor: .windowBackgroundColor)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary, .ultraThinMaterial)
            }
            .buttonStyle(.plain)
            .padding(16)
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.anime.title.preferred)
                .font(.title)
                .fontWeight(.bold)
            
            if let english = viewModel.anime.title.english,
               english != viewModel.anime.title.preferred {
                Text(english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let native = viewModel.anime.title.native {
                Text(native)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let userAnime = viewModel.userAnime {
                ProgressIndicatorView(
                    current: userAnime.progress,
                    total: viewModel.anime.episodes
                )
                
                HStack(spacing: 12) {
                    Button(action: {
                        HapticFeedback.success.trigger()
                        viewModel.incrementProgress()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Increment Episode")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isUpdating)
                    
                    if let episodes = viewModel.anime.episodes,
                       userAnime.progress < episodes {
                        Button(action: {
                            HapticFeedback.success.trigger()
                            Task {
                                await viewModel.updateProgress(episodes)
                            }
                        }) {
                            Text("Mark All Watched")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isUpdating)
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let userAnime = viewModel.userAnime {
                Picker("Status", selection: Binding(
                    get: { userAnime.status },
                    set: { newStatus in
                        Task {
                            await viewModel.updateStatus(newStatus)
                        }
                    }
                )) {
                    ForEach(AnimeStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.menu)
                .disabled(viewModel.isUpdating)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Synopsis Section
    
    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            
            if let synopsis = viewModel.anime.synopsis {
                Text(cleanHTMLTags(synopsis))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            } else {
                Text("No synopsis available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        HStack(spacing: 24) {
            if let episodes = viewModel.anime.episodes {
                metadataItem(
                    icon: "film",
                    label: "Episodes",
                    value: "\(episodes)"
                )
            }
            
            metadataItem(
                icon: "tv",
                label: "Format",
                value: formatDisplayName(viewModel.anime.format)
            )
        }
        .transition(.opacity)
    }
    
    private func metadataItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Genres Section
    
    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genres")
                .font(.headline)
            
            if !viewModel.anime.genres.isEmpty {
                GenreTagsView(genres: viewModel.anime.genres)
            } else {
                Text("No genres available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Score Section
    
    private func scoreSection(score: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Score")
                .font(.headline)
            
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f / 10", score))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 12) {
                // Open in AniList button
                Button(action: {
                    viewModel.openInAniList()
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Open in AniList")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                // Add/Remove from Library button
                if viewModel.isInLibrary {
                    Button(action: {
                        showRemoveConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove from Library")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button(action: {
                        showAddToLibrarySheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Library")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Add to Library Sheet
    
    private var addToLibrarySheet: some View {
        VStack(spacing: 24) {
            Text("Add to Library")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Select a list to add \"\(viewModel.anime.title.preferred)\" to:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(AnimeStatus.allCases, id: \.self) { status in
                    Button(action: {
                        selectedStatus = status
                        Task {
                            await viewModel.addToLibrary(status: status)
                            showAddToLibrarySheet = false
                        }
                    }) {
                        HStack {
                            Image(systemName: statusIcon(for: status))
                            Text(status.displayName)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button("Cancel") {
                showAddToLibrarySheet = false
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(width: 400)
    }
    
    // MARK: - Helper Functions
    
    private func cleanHTMLTags(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(of: "<br>", with: "\n")
        result = result.replacingOccurrences(of: "<br/>", with: "\n")
        result = result.replacingOccurrences(of: "<br />", with: "\n")
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        return result
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
    
    private func statusIcon(for status: AnimeStatus) -> String {
        switch status {
        case .watching: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .planToWatch: return "calendar.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "xmark.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview("In Library") {
    let anime = Anime(
        id: 1,
        title: AnimeTitle(
            romaji: "Kimetsu no Yaiba",
            english: "Demon Slayer",
            native: "鬼滅の刃"
        ),
        coverImage: CoverImage(
            large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx101922-PEn1CTc93blC.jpg",
            medium: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx101922-PEn1CTc93blC.jpg"
        ),
        episodes: 26,
        format: .tv,
        genres: ["Action", "Adventure", "Drama", "Fantasy", "Supernatural"],
        synopsis: "It is the Taisho Period in Japan. Tanjiro, a kindhearted boy who sells charcoal for a living, finds his family slaughtered by a demon. To make matters worse, his younger sister Nezuko, the sole survivor, has been transformed into a demon herself.",
        siteUrl: "https://anilist.co/anime/101922"
    )
    
    let userAnime = UserAnime(
        id: 1,
        anime: anime,
        status: .watching,
        progress: 5,
        score: 9.5,
        sortOrder: 0,
        needsSync: false,
        lastModified: Date()
    )
    
    let mockAnimeService = MockAnimeService()
    let mockSyncService = MockSyncService()
    
    let viewModel = AnimeDetailViewModel(
        anime: anime,
        userAnime: userAnime,
        animeService: mockAnimeService,
        syncService: mockSyncService
    )
    
    return AnimeDetailView(viewModel: viewModel)
}

#Preview("Not in Library") {
    let anime = Anime(
        id: 2,
        title: AnimeTitle(
            romaji: "Shingeki no Kyojin",
            english: "Attack on Titan",
            native: "進撃の巨人"
        ),
        coverImage: CoverImage(
            large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-C6FPmWm59CyP.jpg",
            medium: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx16498-C6FPmWm59CyP.jpg"
        ),
        episodes: 25,
        format: .tv,
        genres: ["Action", "Drama", "Fantasy", "Mystery"],
        synopsis: "Several hundred years ago, humans were nearly exterminated by titans. Titans are typically several stories tall, seem to have no intelligence, devour human beings and, worst of all, seem to do it for the pleasure rather than as a food source.",
        siteUrl: "https://anilist.co/anime/16498"
    )
    
    let mockAnimeService = MockAnimeService()
    let mockSyncService = MockSyncService()
    
    let viewModel = AnimeDetailViewModel(
        anime: anime,
        userAnime: nil,
        animeService: mockAnimeService,
        syncService: mockSyncService
    )
    
    return AnimeDetailView(viewModel: viewModel)
}

// MARK: - Mock Services for Preview

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
