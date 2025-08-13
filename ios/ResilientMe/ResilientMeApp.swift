import SwiftUI

@main
struct ResilientMeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {}

    @StateObject private var analyticsManager = AnalyticsManager()
    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .environmentObject(analyticsManager)
                .preferredColorScheme(.dark)
                .background(Color.resilientBackground.ignoresSafeArea())
                .onAppear {
                    NotificationManager.shared.onDeepLink = { link in
                        if link.contains("recovery") { selectedTab = 2 }
                        else if link.contains("history") { selectedTab = 5 }
                    }
                }
        }
    }
}


