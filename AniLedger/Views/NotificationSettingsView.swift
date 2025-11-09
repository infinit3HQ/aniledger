//
//  NotificationSettingsView.swift
//  AniLedger
//
//  Settings view for managing airing notifications
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("airingNotificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationLeadTime") private var leadTime = 0 // Minutes before airing
    
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Airing Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            checkNotificationPermission()
                        }
                    }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get notified when new episodes of anime you're watching are about to air")
            }
            
            if notificationsEnabled {
                Section {
                    Picker("Notify Me", selection: $leadTime) {
                        Text("When Episode Airs").tag(0)
                        Text("15 Minutes Before").tag(15)
                        Text("30 Minutes Before").tag(30)
                        Text("1 Hour Before").tag(60)
                        Text("2 Hours Before").tag(120)
                    }
                } header: {
                    Text("Timing")
                } footer: {
                    Text("Choose when you want to be notified about new episodes")
                }
                
                Section {
                    HStack {
                        Text("Monitoring Status")
                        Spacer()
                        Text("Active")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Check Interval")
                        Spacer()
                        Text("Every Hour")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Status")
                }
            }
        }
        .navigationTitle("Airing Notifications")
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK") {
                notificationsEnabled = false
            }
        } message: {
            Text("Please enable notifications in System Settings to receive airing alerts")
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus != .authorized {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
