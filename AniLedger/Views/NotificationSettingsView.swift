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
    @State private var pendingNotificationCount = 0
    @State private var showingClearConfirmation = false
    
    let notificationService: NotificationServiceProtocol?
    
    var body: some View {
        Form {
            // Enable/Disable Section
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Airing Notifications")
                        Text("Get notified when new episodes air")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: notificationsEnabled) { _, newValue in
                    if newValue {
                        checkNotificationPermission()
                    }
                }
            }
            
            if notificationsEnabled {
                // Timing Section
                Section("Timing") {
                    Picker("Notify Me", selection: $leadTime) {
                        Text("When Episode Airs").tag(0)
                        Text("15 Minutes Before").tag(15)
                        Text("30 Minutes Before").tag(30)
                        Text("1 Hour Before").tag(60)
                        Text("2 Hours Before").tag(120)
                    }
                }
                
                // Status Section
                Section("Status") {
                    LabeledRow(label: "Monitoring", value: "Active", valueColor: .green)
                    LabeledRow(label: "Check Interval", value: "Every Hour")
                    LabeledRow(label: "Pending", value: "\(pendingNotificationCount)")
                }
                
                // Clear Section
                if pendingNotificationCount > 0 {
                    Section {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Notifications")
                            }
                        }
                    } footer: {
                        Text("Remove \(pendingNotificationCount) scheduled notification\(pendingNotificationCount == 1 ? "" : "s")")
                    }
                }
            }
        }
        .navigationTitle("Airing Notifications")
        .task {
            await loadPendingNotificationCount()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK") {
                notificationsEnabled = false
            }
        } message: {
            Text("Please enable notifications in System Settings to receive airing alerts")
        }
        .alert("Clear All Notifications?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllNotifications()
            }
        } message: {
            Text("This will remove all \(pendingNotificationCount) scheduled airing notifications")
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
    
    private func loadPendingNotificationCount() async {
        guard let service = notificationService else { return }
        pendingNotificationCount = await service.getPendingNotificationCount()
    }
    
    private func clearAllNotifications() {
        notificationService?.cancelAllNotifications()
        pendingNotificationCount = 0
    }
}

// MARK: - Helper Views

private struct LabeledRow: View {
    let label: String
    let value: String
    var valueColor: Color = .secondary
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(valueColor == .secondary ? .regular : .medium)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(notificationService: NotificationService())
    }
}
