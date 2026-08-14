import Foundation
import UserNotifications

/// Handles local reminder notifications for captures.
public final class NotificationManager: @unchecked Sendable {
    public static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Requests notification permissions from the user
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Checks if notifications are authorized
    public func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Schedules a local notification for a capture item
    public func scheduleReminder(for item: CaptureItem) {
        guard let reminderDate = item.reminderDate, reminderDate > Date() else { return }

        // Remove any existing notification for this item first
        cancelReminder(for: item.id)

        let content = UNMutableNotificationContent()
        content.title = item.type.displayName
        content.body = item.content.isEmpty ? "You have a reminder in Catch" : item.content
        content.sound = .default
        content.userInfo = ["captureId": item.id.uuidString]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: "catch-reminder-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    /// Cancels a scheduled notification for an item
    public func cancelReminder(for itemId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["catch-reminder-\(itemId.uuidString)"])
    }
}
