import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let id = PerformanceMetrics.begin("App Launch Configure")
#if canImport(FirebaseCore)
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
            FirebaseConfigurator.configureEmulatorsIfNeeded()
            RemoteConfigManager.shared.fetchAndActivate()
        } else {
            print("[Firebase] GoogleService-Info.plist missing or invalid. Skipping FirebaseApp.configure().")
        }
#endif
#if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
#endif
        PerformanceMetrics.end("App Launch Configure", id: id)
        return true
    }

#if canImport(FirebaseMessaging)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        // Attempt to register token to backend when available
        NotificationManager.shared.registerFCMToken()
    }
#endif
}

#if canImport(FirebaseMessaging)
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Persist or send token to backend
        NotificationManager.shared.registerFCMToken()
    }
}
#endif


