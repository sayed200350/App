import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int
    @StateObject private var rc = RemoteConfigManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)

            RejectionLogView()
                .tabItem {
                    Label("Quick Log", systemImage: "plus.circle.fill")
                }
                .tag(1)

            RecoveryHubView()
                .tabItem {
                    Label("Recovery", systemImage: "heart.text.square.fill")
                }
                .tag(2)

            ChallengeView()
                .tabItem {
                    Label("Challenge", systemImage: "flag.checkered")
                }
                .tag(3)

            if rc.communityEnabled {
                CommunityView()
                    .tabItem {
                        Label("Community", systemImage: "person.3.fill")
                    }
                    .tag(4)
            }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(5)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(6)
        }
        .onAppear { rc.fetchAndActivate() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedTab: .constant(0))
    }
}


