//
//  NotificationService.swift
//  AniLedger
//
//  Service for managing local notifications for airing anime episodes
//

import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleAiringNotification(for anime: UserAnime, episode: Int, airingAt: Date)
    func cancelNotification(for animeId: Int)
    func cancelAllNotifications()
}

class NotificationService: NotificationServiceProtocol {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleAiringNotification(for anime: UserAnime, episode: Int, airingAt: Date) {
        let content = UNMutableNotificationContent()
        content.title = "New Episode Available!"
        content.body = "\(anime.anime.title) - Episode \(episode) is now airing"
        content.sound = .default
        content.badge = 1
        
        // Add anime ID to userInfo for handling taps
        content.userInfo = [
            "animeId": anime.anime.id,
            "episode": episode
        ]
        
        // Schedule notification for airing time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: airingAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "anime-\(anime.anime.id)-episode-\(episode)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotification(for animeId: Int) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.hasPrefix("anime-\(animeId)-") }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
