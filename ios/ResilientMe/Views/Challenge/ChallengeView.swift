import SwiftUI

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

struct ChallengeView: View {
    @StateObject private var manager = ChallengeManager()
    @State private var challenge: Challenge?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let c = challenge {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(c.title).font(.resilientHeadline)
                        Text(c.description).font(.resilientBody)
                        HStack {
                            Text(c.type.displayTitle).font(.caption)
                            Spacer()
                            Text("~ \(c.timeEstimate)").font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    HStack {
                        ResilientButton(title: "Complete", style: .primary) {
                            manager.markCompleted(c)
                            #if canImport(FirebaseAnalytics)
                            Analytics.logEvent("challenge_complete", parameters: [
                                "type": c.type.rawValue,
                                "points": c.points
                            ])
                            #endif
                            challenge = manager.getTodaysChallenge()
                        }
                        ResilientButton(title: "Skip", style: .secondary) {
                            challenge = manager.getTodaysChallenge()
                        }
                    }
                } else {
                    Text("Generating your personalized challenge...")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Streak: \(manager.currentStreak)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Today's Challenge")
            .onAppear { challenge = manager.getTodaysChallenge() }
        }
    }
}

struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeView()
    }
}


