import Foundation

enum ResilienceLevel { case beginner, intermediate, advanced }

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: RejectionType
    let difficulty: ResilienceLevel
    let points: Int
    let timeEstimate: String
}

final class ChallengeManager: ObservableObject {
    @Published var currentStreak: Int = UserDefaults.standard.integer(forKey: "challenge_streak")

    func getTodaysChallenge() -> Challenge {
        let recent = RejectionManager.shared.recent(days: 7)
        let level = getCurrentLevel()
        let mostCommon = recent.map { $0.type }.reduce(into: [:]) { $0[$1, default: 0] += 1 }.max { $0.value < $1.value }?.key ?? .social

        switch (mostCommon, level) {
        case (.dating, .beginner):
            return Challenge(title: "Small Social Step", description: "Start a conversation with one new person today", type: .social, difficulty: .beginner, points: 10, timeEstimate: "5 minutes")
        case (.dating, .intermediate):
            return Challenge(title: "Confidence Builder", description: "Ask someone for their number or social media", type: .dating, difficulty: .intermediate, points: 25, timeEstimate: "10 minutes")
        case (.job, .beginner):
            return Challenge(title: "Application Momentum", description: "Apply to 3 jobs today, focus on quality", type: .job, difficulty: .beginner, points: 15, timeEstimate: "30 minutes")
        case (.job, .intermediate):
            return Challenge(title: "Network Expansion", description: "Reach out to 2 people in your field on LinkedIn", type: .job, difficulty: .intermediate, points: 30, timeEstimate: "20 minutes")
        default:
            return Challenge(title: "Self-Care Check", description: "Do one thing today that makes you feel good", type: .other, difficulty: .beginner, points: 10, timeEstimate: "15 minutes")
        }
    }

    func getCurrentLevel() -> ResilienceLevel {
        let avgImpact = RejectionManager.shared.recent(days: 14).map { $0.emotionalImpact }.reduce(0, +) / max(1, Double(RejectionManager.shared.recent(days: 14).count))
        if avgImpact < 4 { return .advanced }
        if avgImpact < 7 { return .intermediate }
        return .beginner
    }

    func markCompleted(_ challenge: Challenge) {
        let streak = UserDefaults.standard.integer(forKey: "challenge_streak") + 1
        UserDefaults.standard.set(streak, forKey: "challenge_streak")
        currentStreak = streak
    }
}


