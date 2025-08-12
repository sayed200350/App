import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }

            RejectionLogView()
                .tabItem {
                    Label("Quick Log", systemImage: "plus.circle.fill")
                }

            RecoveryHubView()
                .tabItem {
                    Label("Recovery", systemImage: "heart.text.square.fill")
                }

            ChallengeView()
                .tabItem {
                    Label("Challenge", systemImage: "flag.checkered")
                }

            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


