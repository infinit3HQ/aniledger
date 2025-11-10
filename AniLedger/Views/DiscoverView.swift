//
//  DiscoverView.swift
//  AniLedger
//
//  View for discovering new anime (seasonal, upcoming, trending)
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel: DiscoverViewModel
    @State private var selectedAnime: Anime?
    
    private let animeService: AnimeServiceProtocol
    private let syncService: SyncServiceProtocol
    
    init(viewModel: DiscoverViewModel, animeService: AnimeServiceProtocol, syncService: SyncServiceProtocol) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.animeService = animeService
        self.syncService = syncService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            FilterBar(
                selectedGenres: $viewModel.selectedGenres,
                selectedFormats: $viewModel.selectedFormats,
                onFilterChange: {
                    viewModel.applyFilters()
                }
            )
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        VStack(spacing: 24) {
                            DiscoverSectionSkeleton()
                            DiscoverSectionSkeleton()
                            DiscoverSectionSkeleton()
                        }
                        .transition(.opacity)
                    } else if let error = viewModel.error {
                        ErrorStateView(error: error) {
                            viewModel.loadDiscoverContent()
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: 24) {
                            // Current Season Section
                            AnimeSection(
                                title: "Current Season",
                                anime: viewModel.currentSeasonAnime,
                                onAnimeTap: { anime in
                                    HapticFeedback.selection.trigger()
                                    selectedAnime = anime
                                }
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            // Upcoming Section
                            AnimeSection(
                                title: "Upcoming",
                                anime: viewModel.upcomingAnime,
                                onAnimeTap: { anime in
                                    HapticFeedback.selection.trigger()
                                    selectedAnime = anime
                                }
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            // Trending Section
                            AnimeSection(
                                title: "Trending Now",
                                anime: viewModel.trendingAnime,
                                onAnimeTap: { anime in
                                    HapticFeedback.selection.trigger()
                                    selectedAnime = anime
                                }
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Discover")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticFeedback.selection.trigger()
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                .help("Refresh content")
            }
        }
        .onAppear {
            viewModel.loadDiscoverContent()
        }
        .sheet(item: $selectedAnime) { anime in
            AnimeDetailView(viewModel: createDetailViewModel(for: anime))
                .frame(minWidth: 600, idealWidth: 600, maxWidth: 600,
                       minHeight: 700, idealHeight: 700, maxHeight: 700)
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

// MARK: - Filter Bar

struct FilterBar: View {
    @Binding var selectedGenres: Set<String>
    @Binding var selectedFormats: Set<AnimeFormat>
    let onFilterChange: () -> Void
    
    @State private var showingGenrePicker = false
    @State private var showingFormatPicker = false
    
    // Common anime genres
    private let availableGenres = [
        "Action", "Adventure", "Comedy", "Drama", "Fantasy",
        "Horror", "Mystery", "Romance", "Sci-Fi", "Slice of Life",
        "Sports", "Supernatural", "Thriller"
    ].sorted()
    
    var body: some View {
        HStack(spacing: 12) {
            // Genre Filter Button
            Menu {
                ForEach(availableGenres, id: \.self) { genre in
                    Button {
                        toggleGenre(genre)
                    } label: {
                        HStack {
                            Text(genre)
                            if selectedGenres.contains(genre) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                if !selectedGenres.isEmpty {
                    Divider()
                    Button("Clear All") {
                        selectedGenres.removeAll()
                        onFilterChange()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Genres")
                    if !selectedGenres.isEmpty {
                        Text("(\(selectedGenres.count))")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedGenres.isEmpty ? Color.secondary.opacity(0.1) : Color.accentColor.opacity(0.2))
                )
            }
            
            // Format Filter Button
            Menu {
                ForEach(AnimeFormat.allCases, id: \.self) { format in
                    Button {
                        toggleFormat(format)
                    } label: {
                        HStack {
                            Text(format.displayName)
                            if selectedFormats.contains(format) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                if !selectedFormats.isEmpty {
                    Divider()
                    Button("Clear All") {
                        selectedFormats.removeAll()
                        onFilterChange()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tv")
                    Text("Format")
                    if !selectedFormats.isEmpty {
                        Text("(\(selectedFormats.count))")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedFormats.isEmpty ? Color.secondary.opacity(0.1) : Color.accentColor.opacity(0.2))
                )
            }
            
            Spacer()
            
            // Clear All Filters Button
            if !selectedGenres.isEmpty || !selectedFormats.isEmpty {
                Button {
                    selectedGenres.removeAll()
                    selectedFormats.removeAll()
                    onFilterChange()
                } label: {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
        onFilterChange()
    }
    
    private func toggleFormat(_ format: AnimeFormat) {
        if selectedFormats.contains(format) {
            selectedFormats.remove(format)
        } else {
            selectedFormats.insert(format)
        }
        onFilterChange()
    }
}

// MARK: - Anime Section

struct AnimeSection: View {
    let title: String
    let anime: [Anime]
    let onAnimeTap: (Anime) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Spacer()
                
                Text("\(anime.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            if anime.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "No anime match your current filters."
                )
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(anime) { animeItem in
                            AnimeCardView(anime: animeItem, width: 150)
                                .onTapGesture {
                                    onAnimeTap(animeItem)
                                }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 240)
            }
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: KiroError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Error icon based on error type
            Image(systemName: errorIcon)
                .font(.system(size: 60))
                .foregroundColor(errorColor)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(error.userFriendlyTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
            }
            
            if error.isRetryable {
                Button(action: onRetry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .fontWeight(.medium)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var errorIcon: String {
        switch error {
        case .noInternetConnection:
            return "wifi.slash"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .serverUnavailable:
            return "server.rack"
        case .rateLimitExceeded:
            return "hourglass"
        case .authenticationFailed:
            return "person.crop.circle.badge.exclamationmark"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .noInternetConnection, .timeout:
            return .orange
        case .serverUnavailable, .rateLimitExceeded:
            return .yellow
        case .authenticationFailed:
            return .red
        default:
            return .orange
        }
    }
}

// MARK: - AnimeFormat Display Name Extension

extension AnimeFormat {
    var displayName: String {
        switch self {
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
    
    func setNotificationService(_ service: NotificationServiceProtocol) {
        // No-op for preview
    }
}

// MARK: - Preview

#Preview {
    let apiClient = MockAniListAPIClient()
    let animeService = MockAnimeService()
    let syncService = MockSyncService()
    
    return NavigationStack {
        DiscoverView(
            viewModel: DiscoverViewModel(
                apiClient: apiClient,
                animeService: animeService
            ),
            animeService: animeService,
            syncService: syncService
        )
    }
}
