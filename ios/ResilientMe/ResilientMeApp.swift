import SwiftUI

@main
struct ResilientMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {}

    @StateObject private var analyticsManager = AnalyticsManager()
    @StateObject private var router = AppRouter.shared
    @StateObject private var age = AgeVerificationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if age.isVerified {
                    ContentView()
                        .environmentObject(analyticsManager)
                        .environmentObject(router)
                } else {
                    AgeGateView()
                }
            }
            .preferredColorScheme(.dark)
            .background(Color.resilientBackground.ignoresSafeArea())
        }
    }
}


