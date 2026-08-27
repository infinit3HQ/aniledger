//
//  MockNotificationService.swift
//  AniLedgerTests
//
//  Mock implementation of NotificationServiceProtocol for testing
//

import Combine
import Foundation
@testable import AniLedger

class MockNotificationService: NotificationServiceProtocol {
    let deepLinkPublisher = PassthroughSubject<Int, Never>()
    
    var requestAuthorizationCallCount = 0
    var scheduleAiringNotificationCallCount = 0
    var cancelNotificationByAnimeIdCallCount = 0
    var cancelNotificationByEpisodeCallCount = 0
    var cancelAllNotificationsCallCount = 0
    
    var scheduledNotifications: [(anime: UserAnime, episode: Int, airingAt: Date)] = []
    
    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return true
    }
    
    func scheduleAiringNotification(for anime: UserAnime, episode: Int, airingAt: Date) {
        scheduleAiringNotificationCallCount += 1
        scheduledNotifications.append((anime: anime, episode: episode, airingAt: airingAt))
    }
    
    func cancelNotification(for animeId: Int) {
        cancelNotificationByAnimeIdCallCount += 1
    }
    
    func cancelNotification(for animeId: Int, episode: Int) {
        cancelNotificationByEpisodeCallCount += 1
    }
    
    func cancelAllNotifications() {
        cancelAllNotificationsCallCount += 1
        scheduledNotifications.removeAll()
    }
    
    func getPendingNotificationCount() async -> Int {
        return scheduledNotifications.count
    }
    
    func reset() {
        requestAuthorizationCallCount = 0
        scheduleAiringNotificationCallCount = 0
        cancelNotificationByAnimeIdCallCount = 0
        cancelNotificationByEpisodeCallCount = 0
        cancelAllNotificationsCallCount = 0
        scheduledNotifications.removeAll()
    }
}
