//
//  NotificationService.swift
//  AniLedger
//
//  Service for managing local notifications for airing anime episodes
//

import Combine
import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    var deepLinkPublisher: PassthroughSubject<Int, Never> { get }
    func requestAuthorization() async -> Bool
    func scheduleAiringNotification(for anime: UserAnime, episode: Int, airingAt: Date)
    func cancelNotification(for animeId: Int)
    func cancelNotification(for animeId: Int, episode: Int)
    func cancelAllNotifications()
    func getPendingNotificationCount() async -> Int
}

class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    private let notificationCenter = UNUserNotificationCenter.current()
    let deepLinkPublisher = PassthroughSubject<Int, Never>()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
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
        content.body = "\(anime.anime.title.preferred) - Episode \(episode) is now airing"
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
    
    func cancelNotification(for animeId: Int, episode: Int) {
        let identifier = "anime-\(animeId)-episode-\(episode)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func getPendingNotificationCount() async -> Int {
        await notificationCenter.pendingNotificationRequests().count
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let animeId = userInfo["animeId"] as? Int {
            // Publish deep link event
            DispatchQueue.main.async {
                self.deepLinkPublisher.send(animeId)
            }
        }
        
        completionHandler()
    }
}
