import Foundation
import UserNotifications
import SwiftUI

public struct InAppToast: Identifiable, Equatable {
    public let id: UUID = UUID()
    public let title: String
    public let message: String
    public let icon: String
    public let color: Color
    public let createdAt: Date = Date.now

    public init(title: String, message: String, icon: String = "bell.fill", color: Color = Color.accentColor) {
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
    }
}

@Observable
@MainActor
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    public var isPermissionGranted: Bool = false
    public var currentToast: InAppToast? = nil
    public var taskRemindersEnabled: Bool = true
    public var leadTimeMinutes: Int = 0 // 0 = at time, 5 = 5m before, 10 = 10m before
    public var streakReminderEnabled: Bool = true
    public var streakReminderHour: Int = 20 // 8:00 PM

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task {
            await checkPermission()
        }
    }

    public func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isPermissionGranted = (settings.authorizationStatus == .authorized)
    }

    @discardableResult
    public func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            self.isPermissionGranted = granted
            if granted && streakReminderEnabled {
                scheduleStreakReminder()
            }
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    public func showToast(title: String, message: String, icon: String = "bell.fill", color: Color = Color.accentColor) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.currentToast = InAppToast(title: title, message: message, icon: icon, color: color)
        }

        // Auto-dismiss after 4 seconds
        let currentId = self.currentToast?.id
        Task {
            try? await Task.sleep(for: .seconds(4))
            if self.currentToast?.id == currentId {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.currentToast = nil
                }
            }
        }
    }

    public func dismissToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.currentToast = nil
        }
    }

    // Schedule System Notification for a Task
    public func scheduleTaskReminder(for task: TaskItem, leadMinutes: Int? = nil) {
        guard taskRemindersEnabled, !task.isCompleted else { return }
        let lead = leadMinutes ?? leadTimeMinutes
        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -lead,
            to: task.effectiveStartTime
        ) ?? task.effectiveStartTime

        guard triggerDate > Date.now else { return }

        let content = UNMutableNotificationContent()
        content.title = lead > 0 ? "Upcoming Task in \(lead)m" : "Time for Task!"
        content.body = task.title
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString, "title": task.title]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    public func cancelTaskReminder(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task-\(task.id.uuidString)"]
        )
    }

    // Daily Evening Streak Reminder
    public func scheduleStreakReminder() {
        guard streakReminderEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["daily-streak-reminder"]
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Keep Your Streak Alive!"
        content.body = "You're on track! Take a minute to check off completed tasks and review tomorrow."
        content.sound = .default

        var components = DateComponents()
        components.hour = streakReminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-streak-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // UNUserNotificationCenterDelegate: Display Toast When Notification Fires in Foreground
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let title = notification.request.content.title
        let body = notification.request.content.body
        let isStreak = title.contains("Streak")
        Task { @MainActor in
            NotificationManager.shared.showToast(
                title: title,
                message: body,
                icon: isStreak ? "flame.fill" : "bell.badge.fill",
                color: isStreak ? Color.orange : Color.accentColor
            )
        }
        return [.banner, .sound]
    }
}
