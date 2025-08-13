import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct ChallengeView: View {
    @StateObject private var manager = ChallengeManager()
    @State private var challenge: Challenge?
    @State private var showingShare = false

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
                            AnalyticsManager.trackChallengeComplete()
                            showingShare = true
                            loadChallenge()
                        }
                        ResilientButton(title: "Skip", style: .secondary) {
                            AnalyticsManager.trackChallengeSkip()
                            loadChallenge()
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
            .onAppear { loadChallenge() }
            .sheet(isPresented: $showingShare) {
                let text = "I just completed today’s resilience challenge on ResilientMe!"
                ShareSheet(items: [text])
            }
        }
    }

    private func loadChallenge() {
        #if canImport(FirebaseFirestore)
        if FirebaseManager.shared.isConfigured, let uid = FirebaseManager.shared.currentUser?.uid {
            let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date())).prefix(10)
            let doc = Firestore.firestore().collection("users").document(uid).collection("challenges").document(String(today))
            doc.getDocument { snap, _ in
                if let data = snap?.data(),
                   let title = data["title"] as? String,
                   let description = data["description"] as? String,
                   let typeRaw = data["type"] as? String,
                   let type = RejectionType(rawValue: typeRaw),
                   let timeEstimate = data["timeEstimate"] as? String {
                    self.challenge = Challenge(title: title, description: description, type: type, difficulty: .beginner, points: data["points"] as? Int ?? 10, timeEstimate: timeEstimate)
                    return
                }
                self.challenge = manager.getTodaysChallenge()
            }
            return
        }
        #endif
        self.challenge = manager.getTodaysChallenge()
    }
}

struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeView()
    }
}


