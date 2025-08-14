import Foundation
import UserNotifications

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
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

    // MARK: - Push (FCM)
    func registerFCMToken() {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().token { token, error in
            if let error = error { print("[FCM] Token fetch error: \(error)"); return }
            guard let token = token else { return }
            #if canImport(FirebaseFirestore)
            if let uid = FirebaseManager.shared.currentUser?.uid {
                let db = Firestore.firestore()
                db.collection("users").document(uid).collection("fcmTokens").document(token).setData([
                    "token": token,
                    "platform": "ios",
                    "createdAt": FieldValue.serverTimestamp()
                ], merge: true)
            }
            #endif
        }
        #endif
    }

    // Track notification opens and navigate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("notification_open", parameters: ["category": "local_or_push"])
        #endif
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            if type == "recovery-followup" { AppRouter.shared.navigate(to: .recovery) }
            else if type == "daily-checkin" { AppRouter.shared.navigate(to: .log) }
        } else {
            let id = response.notification.request.identifier
            if id == "daily-checkin" { AppRouter.shared.navigate(to: .log) }
            else if id.hasPrefix("recovery-followup-") { AppRouter.shared.navigate(to: .recovery) }
        }
        completionHandler()
    }
}


