import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var onDeepLink: ((String) -> Void)?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let openRecovery = UNNotificationAction(identifier: "OPEN_RECOVERY", title: "Open Recovery", options: [.foreground])
        let dailyCategory = UNNotificationCategory(identifier: "DAILY_CHECKIN", actions: [openRecovery], intentIdentifiers: [], options: [])
        let recoveryCategory = UNNotificationCategory(identifier: "RECOVERY_FOLLOWUP", actions: [openRecovery], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([dailyCategory, recoveryCategory])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDailyCheckIn(hour: Int = 20) {
        // remove existing
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling today?"
        content.body = "Take 30 seconds to check in with yourself"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func setDailyCheckInEnabled(_ enabled: Bool) {
        if enabled {
            scheduleDailyCheckIn(hour: 20)
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
        }
    }

    func scheduleRecoveryFollowUps() {
        let recentHigh = RejectionManager.shared.recentHighImpact()
        for r in recentHigh {
            let content = UNMutableNotificationContent()
            content.title = "How are you doing?"
            content.body = "Yesterday was tough. You're stronger than you know."
            content.sound = .default
            content.categoryIdentifier = "RECOVERY_FOLLOWUP"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
            let request = UNNotificationRequest(identifier: "recovery-followup-\(r.id.uuidString)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func setRecoveryFollowUpsEnabled(_ enabled: Bool) {
        if enabled { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map { $0.identifier }.filter { $0.hasPrefix("recovery-followup-") }
            if !ids.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    // Present notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    // Handle deep-link from notification response
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let link = userInfo["deep_link"] as? String {
            onDeepLink?(link)
        } else if response.notification.request.content.categoryIdentifier == "DAILY_CHECKIN" || response.actionIdentifier == "OPEN_RECOVERY" {
            onDeepLink?("resilientme://recovery")
        }
        completionHandler()
    }
}


