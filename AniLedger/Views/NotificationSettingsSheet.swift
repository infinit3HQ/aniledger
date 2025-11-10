//
//  NotificationSettingsSheet.swift
//  AniLedger
//
//  Modal sheet for managing airing notifications
//

import SwiftUI
import UserNotifications

struct NotificationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("airingNotificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationLeadTime") private var leadTime = 0
    
    @State private var showingPermissionAlert = false
    @State private var pendingNotificationCount = 0
    @State private var showingClearConfirmation = false
    
    let notificationService: NotificationServiceProtocol?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ModalHeader(title: "Airing Notifications") {
                dismiss()
            }
            
            // Content
            Form {
                // Enable/Disable Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Enable Airing Notifications")
                                .font(.body)
                            Text("Get notified when new episodes of anime you're watching are about to air")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                    .toggleStyle(.switch)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            checkNotificationPermission()
                        }
                    }
                }
                .padding(.top, 8)
                
                if notificationsEnabled {
                    // Timing Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notification Timing")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Notify me", selection: $leadTime) {
                                Text("When Episode Airs").tag(0)
                                Text("15 Minutes Before").tag(15)
                                Text("30 Minutes Before").tag(30)
                                Text("1 Hour Before").tag(60)
                                Text("2 Hours Before").tag(120)
                            }
                            .pickerStyle(.radioGroup)
                            .labelsHidden()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Status Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monitoring Status")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                StatusRow(
                                    icon: "checkmark.circle.fill",
                                    label: "Monitoring",
                                    value: "Active",
                                    valueColor: .green
                                )
                                
                                StatusRow(
                                    icon: "clock.fill",
                                    label: "Check Interval",
                                    value: "Every Hour",
                                    valueColor: .secondary
                                )
                                
                                StatusRow(
                                    icon: "bell.badge.fill",
                                    label: "Pending Notifications",
                                    value: "\(pendingNotificationCount)",
                                    valueColor: pendingNotificationCount > 0 ? .blue : .secondary
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Clear Section
                    if pendingNotificationCount > 0 {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    showingClearConfirmation = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                        Text("Clear All Notifications")
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Text("This will remove all \(pendingNotificationCount) scheduled notification\(pendingNotificationCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .formStyle(.grouped)
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

private struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .secondary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(valueColor)
                .frame(width: 20)
            
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationSettingsSheet(notificationService: NotificationService())
}
