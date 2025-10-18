//
//  SearchView.swift
//  AniLedger
//
//  View for searching anime by title
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @State private var selectedAnime: Anime?
    
    private let animeService: AnimeServiceProtocol
    private let syncService: SyncServiceProtocol
    
    init(viewModel: SearchViewModel, animeService: AnimeServiceProtocol, syncService: SyncServiceProtocol) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.animeService = animeService
        self.syncService = syncService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
            
            Divider()
            
            // Content Area
            contentArea
        }
        .navigationTitle("Search")
        .sheet(item: $selectedAnime) { anime in
            AnimeDetailView(viewModel: createDetailViewModel(for: anime))
                .frame(minWidth: 600, idealWidth: 600, maxWidth: 600,
                       minHeight: 700, idealHeight: 700, maxHeight: 700)
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
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search anime by title...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 20, height: 20)
            }
        }
        .padding()
    }
    
    // MARK: - Content Area
    
    @ViewBuilder
    private var contentArea: some View {
        if viewModel.searchText.isEmpty {
            emptySearchState
        } else if viewModel.isLoading && viewModel.searchResults.isEmpty {
            LoadingView(message: "Searching...", size: .medium)
        } else if let error = viewModel.error {
            errorState(error: error)
        } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
            noResultsState
        } else {
            searchResultsList
        }
    }
    
    // MARK: - Empty Search State
    
    private var emptySearchState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Search for Anime",
            message: "Enter a title to search for anime on AniList."
        )
    }
    
    // MARK: - No Results State
    
    private var noResultsState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "We couldn't find any anime matching \"\(viewModel.searchText)\". Try a different search term."
        )
    }
    
    // MARK: - Error State
    
    private func errorState(error: KiroError) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Search Failed",
            message: error.localizedDescription,
            actionTitle: "Retry",
            action: {
                Task {
                    await viewModel.search(query: viewModel.searchText)
                }
            }
        )
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { anime in
                    SearchResultRow(anime: anime)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticFeedback.selection.trigger()
                            selectedAnime = anime
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                    if anime.id != viewModel.searchResults.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.vertical, 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.searchResults.count)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDetailViewModel(for anime: Anime) -> AnimeDetailViewModel {
        AnimeDetailViewModel(
            anime: anime,
            animeService: animeService,
            syncService: syncService
        )
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let anime: Anime
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover Image
            AsyncImageView(
                url: anime.coverImage.medium,
                width: 60,
                height: 84
            )
            .cornerRadius(6)
            .shadow(radius: isHovered ? 4 : 2)
            
            // Anime Info
            VStack(alignment: .leading, spacing: 6) {
                Text(anime.title.preferred)
                    .font(.headline)
                    .lineLimit(2)
                
                if let english = anime.title.english,
                   english != anime.title.preferred {
                    Text(english)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if let episodes = anime.episodes {
                        Label("\(episodes) eps", systemImage: "film")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label(formatDisplayName(anime.format), systemImage: "tv")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !anime.genres.isEmpty {
                    Text(anime.genres.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1.0 : 0.5)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
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

// MARK: - Mock Services for Preview

private class MockAniListAPIClient: AniListAPIClientProtocol {
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T {
        throw KiroError.networkError(underlying: NSError(domain: "Preview", code: 0))
    }
    
    func execute<T: Decodable>(mutation: GraphQLMutation) async throws -> T {
        throw KiroError.networkError(underlying: NSError(domain: "Preview", code: 0))
    }
}

private class MockSyncService: SyncServiceProtocol {
    func syncAll() async throws {
        // No-op for mock
    }
    
    func syncUserLists() async throws {
        // No-op for mock
    }
    
    func processSyncQueue() async throws {
        // No-op for mock
    }
    
    func queueOperation(_ operation: SyncOperation) {
        // No-op for mock
    }
}

private class MockAnimeService: AnimeServiceProtocol {
    func addAnimeToLibrary(_ anime: Anime, status: AnimeStatus, progress: Int, score: Double?) throws -> UserAnime {
        UserAnime(
            id: anime.id,
            anime: anime,
            status: status,
            progress: progress,
            score: score,
            sortOrder: 0,
            needsSync: false,
            lastModified: Date()
        )
    }
    
    func updateAnimeProgress(_ userAnimeId: Int, progress: Int) throws -> UserAnime {
        fatalError("Not implemented in mock")
    }
    
    func updateAnimeStatus(_ userAnimeId: Int, status: AnimeStatus) throws -> UserAnime {
        fatalError("Not implemented in mock")
    }
    
    func updateAnimeScore(_ userAnimeId: Int, score: Double?) throws -> UserAnime {
        fatalError("Not implemented in mock")
    }
    
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws {
        // No-op for mock
    }
    
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime] {
        return []
    }
    
    func fetchAllUserAnime() throws -> [UserAnime] {
        return []
    }
    
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime {
        fatalError("Not implemented in mock")
    }
    
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws {
        // No-op for mock
    }
    
    func getUserAnime(byId id: Int) throws -> UserAnime? {
        return nil
    }
    
    func getUserAnime(byAnimeId animeId: Int) throws -> UserAnime? {
        return nil
    }
}

// MARK: - Preview

#Preview("Empty State") {
    let apiClient = MockAniListAPIClient()
    let animeService = MockAnimeService()
    let syncService = MockSyncService()
    
    return NavigationStack {
        SearchView(
            viewModel: SearchViewModel(
                apiClient: apiClient,
                animeService: animeService
            ),
            animeService: animeService,
            syncService: syncService
        )
    }
}

#Preview("With Results") {
    let apiClient = MockAniListAPIClient()
    let animeService = MockAnimeService()
    let syncService = MockSyncService()
    
    let viewModel = SearchViewModel(
        apiClient: apiClient,
        animeService: animeService
    )
    
    // Simulate search results
    viewModel.searchText = "Demon Slayer"
    viewModel.searchResults = [
        Anime(
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
            genres: ["Action", "Fantasy", "Supernatural"],
            synopsis: "A boy fights demons to save his sister.",
            siteUrl: "https://anilist.co/anime/101922"
        ),
        Anime(
            id: 2,
            title: AnimeTitle(
                romaji: "Kimetsu no Yaiba: Mugen Ressha-hen",
                english: "Demon Slayer: Mugen Train",
                native: "鬼滅の刃 無限列車編"
            ),
            coverImage: CoverImage(
                large: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx142329-jt2F8kVXI4p1.jpg",
                medium: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx142329-jt2F8kVXI4p1.jpg"
            ),
            episodes: 1,
            format: .movie,
            genres: ["Action", "Fantasy", "Drama"],
            synopsis: "The movie adaptation of the Mugen Train arc.",
            siteUrl: "https://anilist.co/anime/142329"
        )
    ]
    
    return NavigationStack {
        SearchView(
            viewModel: viewModel,
            animeService: animeService,
            syncService: syncService
        )
    }
}
