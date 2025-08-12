import SwiftUI

@main
struct ResilientMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {}

    @StateObject private var analyticsManager = AnalyticsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(analyticsManager)
                .preferredColorScheme(.dark)
                .background(Color.resilientBackground.ignoresSafeArea())
        }
    }
}


