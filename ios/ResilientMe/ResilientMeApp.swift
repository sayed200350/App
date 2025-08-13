import SwiftUI

@main
struct ResilientMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {}

    @StateObject private var analyticsManager = AnalyticsManager()
    @StateObject private var router = AppRouter.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(analyticsManager)
                .environmentObject(router)
                .preferredColorScheme(.dark)
                .background(Color.resilientBackground.ignoresSafeArea())
        }
    }
}


