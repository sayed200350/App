import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
                .tag(AppTab.dashboard)

            RejectionLogView()
                .tabItem { Label("Quick Log", systemImage: "plus.circle.fill") }
                .tag(AppTab.log)

            RecoveryHubView()
                .tabItem { Label("Recovery", systemImage: "heart.text.square.fill") }
                .tag(AppTab.recovery)

            ChallengeView()
                .tabItem { Label("Challenge", systemImage: "flag.checkered") }
                .tag(AppTab.challenge)

            if RemoteConfigManager.shared.communityEnabled {
                CommunityView()
                    .tabItem { Label("Community", systemImage: "person.3.fill") }
                    .tag(AppTab.community)
            }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(AppTab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


