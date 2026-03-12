import Foundation
import UserNotifications

enum NotificationService {
    static let categoryId = "REMINDER_CATEGORY"
    static let recordActionId = "RECORD_ACTION"
    static let reminderIdKey = "reminder_id"

    static func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    static func registerCategory() {
        let recordAction = UNNotificationAction(
            identifier: recordActionId,
            title: L("reminder_action_record"),
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: [recordAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func scheduleReminder(_ reminder: Reminder, currencyCode: String) {
        cancelReminder(id: reminder.id)

        guard reminder.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        let amountText = AmountFormatter.format(reminder.amount, currencyCode: currencyCode)
        content.body = L("reminder_notification_body %@", amountText)
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.userInfo = [reminderIdKey: reminder.id]

        var dateComponents = DateComponents()
        dateComponents.hour = reminder.triggerHour
        dateComponents.minute = reminder.triggerMinute

        switch reminder.frequencyEnum {
        case .daily:
            break
        case .weekly:
            dateComponents.weekday = reminder.triggerDay ?? 1
        case .monthly:
            dateComponents.day = reminder.triggerDay ?? 1
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Failed to schedule: \(error)")
            }
        }
    }

    static func cancelReminder(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func rescheduleAll(reminders: [Reminder], currencyCode: String) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for reminder in reminders where reminder.isEnabled {
            scheduleReminder(reminder, currencyCode: currencyCode)
        }
    }
}
