import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // MARK: - Expiration Notifications

    func scheduleExpirationReminder(for item: GroceryItem, expirationDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Item Expiring Soon"
        content.body = "\(item.name) will expire in 2 days. Use it soon to avoid waste!"
        content.sound = .default
        content.categoryIdentifier = "EXPIRATION"

        // Schedule 2 days before expiration
        let twoDaysBefore = Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: expirationDate
        ) ?? expirationDate

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: twoDaysBefore
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "expiration-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // MARK: - Purchase Reminders

    func schedulePurchaseReminder(for item: GroceryItem, predictedDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Buy"
        content.body = "You usually buy \(item.name) around this time. Add it to your shopping list?"
        content.sound = .default
        content.categoryIdentifier = "PURCHASE_REMINDER"

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: predictedDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "purchase-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Budget Alerts

    func scheduleBudgetAlert(budgetName: String, percentageUsed: Double) {
        guard percentageUsed >= 80 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.body = "You've used \(Int(percentageUsed))% of your \(budgetName) budget"
        content.sound = .default
        content.categoryIdentifier = "BUDGET_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget-alert-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
