//
//  AiringScheduleService.swift
//  AniLedger
//
//  Service for monitoring airing schedules and triggering notifications
//

import Foundation
import Combine

protocol AiringScheduleServiceProtocol {
    func startMonitoring()
    func stopMonitoring()
    func checkForNewEpisodes() async throws
}

class AiringScheduleService: AiringScheduleServiceProtocol {
    private let animeService: AnimeServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let apiClient: AniListAPIClientProtocol
    
    private var monitoringTimer: Timer?
    private let checkInterval: TimeInterval = 3600 // Check every hour
    
    init(
        animeService: AnimeServiceProtocol,
        notificationService: NotificationServiceProtocol,
        apiClient: AniListAPIClientProtocol
    ) {
        self.animeService = animeService
        self.notificationService = notificationService
        self.apiClient = apiClient
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        stopMonitoring() // Clear any existing timer
        
        // Check immediately
        Task {
            try? await checkForNewEpisodes()
        }
        
        // Schedule periodic checks
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.checkForNewEpisodes()
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Check for New Episodes
    
    func checkForNewEpisodes() async throws {
        // Get all anime in "Watching" status
        let watchingAnime = try animeService.fetchAnimeByStatus(.watching)
        
        // Fetch airing schedule for each anime
        for userAnime in watchingAnime {
            try await checkAiringSchedule(for: userAnime)
        }
    }
    
    private func checkAiringSchedule(for userAnime: UserAnime) async throws {
        let query = AiringScheduleQuery(mediaId: userAnime.anime.id)
        let response: MediaDetailResponse = try await apiClient.execute(query: query)
        
        guard let airingEpisode = response.Media.nextAiringEpisode else {
            // No upcoming episode
            return
        }
        
        let airingDate = Date(timeIntervalSince1970: TimeInterval(airingEpisode.airingAt))
        let now = Date()
        
        // Only schedule notifications for episodes airing within the next 7 days
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        if airingDate > now && airingDate <= sevenDaysFromNow {
            // Check if user has already watched this episode
            if userAnime.progress < airingEpisode.episode {
                notificationService.scheduleAiringNotification(
                    for: userAnime,
                    episode: airingEpisode.episode,
                    airingAt: airingDate
                )
            }
        }
    }
}

// MARK: - GraphQL Query

struct AiringScheduleQuery: GraphQLQuery {
    let mediaId: Int
    
    var queryString: String {
        """
        query ($id: Int) {
          Media(id: $id) {
            id
            nextAiringEpisode {
              airingAt
              timeUntilAiring
              episode
            }
          }
        }
        """
    }
    
    var variables: [String: Any]? {
        ["id": mediaId]
    }
}

struct MediaDetailResponse: Decodable {
    let Media: MediaDetail
}

struct MediaDetail: Decodable {
    let id: Int
    let nextAiringEpisode: AiringEpisode?
}
