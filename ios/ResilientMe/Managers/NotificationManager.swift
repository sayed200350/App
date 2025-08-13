import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var onDeepLink: ((String) -> Void)?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDailyCheckIn(hour: Int = 20) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling today?"
        content.body = "Take 30 seconds to check in with yourself"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleRecoveryFollowUps() {
        let recentHigh = RejectionManager.shared.recentHighImpact()
        for r in recentHigh {
            let content = UNMutableNotificationContent()
            content.title = "How are you doing?"
            content.body = "Yesterday was tough. You're stronger than you know."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
            let request = UNNotificationRequest(identifier: "recovery-followup-\(r.id.uuidString)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
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
        }
        completionHandler()
    }
}


