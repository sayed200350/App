import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
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
        } else {
            print("[Firebase] GoogleService-Info.plist missing or invalid. Skipping FirebaseApp.configure().")
        }
#endif
        // Initialize notification handling early
        _ = NotificationManager.shared
        PerformanceMetrics.end("App Launch Configure", id: id)
        return true
    }
}


