//
//  SeasonsView.swift
//  AniLedger
//
//  View for browsing anime by season and year
//

import SwiftUI

struct SeasonsView: View {
    @StateObject private var viewModel: SeasonsViewModel
    @State private var selectedAnime: Anime?
    
    private let animeService: AnimeServiceProtocol
    private let syncService: SyncServiceProtocol
    
    init(viewModel: SeasonsViewModel, animeService: AnimeServiceProtocol, syncService: SyncServiceProtocol) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.animeService = animeService
        self.syncService = syncService
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Season and Year Selector
            seasonYearPicker
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        DiscoverSectionSkeleton()
                            .transition(.opacity)
                    } else if let error = viewModel.error {
                        ErrorStateView(error: error) {
                            viewModel.loadSeasonalAnime()
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    } else if viewModel.seasonalAnime.isEmpty {
                        EmptyStateView(
                            icon: "calendar",
                            title: "No Anime Found",
                            message: "No anime found for \(viewModel.selectedSeason.displayName) \(viewModel.selectedYear)"
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        // Anime Grid
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
                        ], spacing: 20) {
                            ForEach(viewModel.seasonalAnime) { anime in
                                AnimeCardView(anime: anime, width: 150)
                                    .onTapGesture {
                                        HapticFeedback.selection.trigger()
                                        selectedAnime = anime
                                    }
                            }
                        }
                        .padding()
                        .transition(.opacity)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationTitle("Seasons")
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
            viewModel.loadSeasonalAnime()
        }
        .sheet(item: $selectedAnime) { anime in
            AnimeDetailView(viewModel: createDetailViewModel(for: anime))
                .frame(minWidth: 600, idealWidth: 600, maxWidth: 600,
                       minHeight: 700, idealHeight: 700, maxHeight: 700)
        }
    }
    
    // MARK: - Season and Year Picker
    
    private var seasonYearPicker: some View {
        HStack(spacing: 16) {
            // Season Picker
            Picker("Season", selection: $viewModel.selectedSeason) {
                ForEach(AnimeSeason.allCases, id: \.self) { season in
                    Text(season.displayName)
                        .tag(season)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            .onChange(of: viewModel.selectedSeason) { _, _ in
                viewModel.loadSeasonalAnime()
            }
            
            Spacer()
            
            // Year Picker
            HStack(spacing: 8) {
                Button {
                    HapticFeedback.selection.trigger()
                    viewModel.decrementYear()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                
                Text("\(viewModel.selectedYear)")
                    .font(.headline)
                    .frame(minWidth: 60)
                
                Button {
                    HapticFeedback.selection.trigger()
                    viewModel.incrementYear()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.selectedYear >= viewModel.currentYear)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            
            // Quick Jump to Current Season
            Button {
                HapticFeedback.selection.trigger()
                viewModel.jumpToCurrentSeason()
            } label: {
                Text("Current")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
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

// MARK: - AnimeSeason Enum

enum AnimeSeason: String, CaseIterable {
    case winter = "WINTER"
    case spring = "SPRING"
    case summer = "SUMMER"
    case fall = "FALL"
    
    var displayName: String {
        switch self {
        case .winter: return "Winter"
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        }
    }
    
    var icon: String {
        switch self {
        case .winter: return "snowflake"
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "leaf.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    let apiClient = MockAniListAPIClient()
    let animeService = MockAnimeService()
    let syncService = MockSyncService()
    
    return NavigationStack {
        SeasonsView(
            viewModel: SeasonsViewModel(apiClient: apiClient),
            animeService: animeService,
            syncService: syncService
        )
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
    func syncAll() async throws {}
    func syncUserLists() async throws {}
    func processSyncQueue() async throws {}
    func queueOperation(_ operation: SyncOperation) {}
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
    
    func deleteAnimeFromLibrary(_ userAnimeId: Int) throws {}
    
    func fetchAnimeByStatus(_ status: AnimeStatus) throws -> [UserAnime] {
        return []
    }
    
    func fetchAllUserAnime() throws -> [UserAnime] {
        return []
    }
    
    func moveAnimeBetweenLists(_ userAnimeId: Int, toStatus: AnimeStatus) throws -> UserAnime {
        fatalError("Not implemented in mock")
    }
    
    func reorderAnime(in status: AnimeStatus, from sourceIndex: Int, to destinationIndex: Int) throws {}
    
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
