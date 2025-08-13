import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

struct WeeklyStats {
    let totalLogs: Int
    let highImpact: Int
    let averageImpact: Double
}

final class AnalyticsManager: ObservableObject {
    @Published var currentResilienceScore: Double = 64
    @Published var weeklyStats: WeeklyStats = .init(totalLogs: 0, highImpact: 0, averageImpact: 0)
    @Published var timeframe: TimeFrame = .week
    @Published var recoveryTrend: [TrendPoint] = []

    // MARK: - Tracking
    static func logEvent(_ name: String, params: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: params)
        #endif
    }

    static func trackRejectionLogged(type: RejectionType) {
        logEvent("rejection_log", params: ["type": type.rawValue])
    }

    static func trackChallengeComplete() {
        logEvent("challenge_complete")
    }

    static func trackChallengeSkip() {
        logEvent("challenge_skip")
    }

    static func trackCommunityPost() {
        logEvent("community_post")
    }

    static func trackReactionAdd(_ reaction: Reaction) {
        logEvent("reaction_add", params: ["reaction": reaction.rawValue])
    }

    static func trackScreenView(_ name: String) {
        logEvent(AnalyticsEventScreenView, params: [AnalyticsParameterScreenName: name])
    }

    // MARK: - Derived metrics
    func recalculate() {
        let items = RejectionManager.shared.recent(days: timeframe.days)
        let total = items.count
        let high = items.filter { $0.emotionalImpact >= 7 }.count
        let avg = items.map { $0.emotionalImpact }.reduce(0, +) / Double(max(1, total))
        let trend = self.generateTrend(from: items)
        DispatchQueue.main.async {
            self.weeklyStats = .init(totalLogs: total, highImpact: high, averageImpact: avg)
            self.currentResilienceScore = max(5, 100 - (avg * 7))
            self.recoveryTrend = trend
        }
    }

    private func generateTrend(from items: [RejectionEntry]) -> [TrendPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: $0.timestamp) }
        let sortedDays = grouped.keys.sorted()
        return sortedDays.map { day in
            let dayItems = grouped[day] ?? []
            let avg = dayItems.map { $0.emotionalImpact }.reduce(0, +) / Double(max(1, dayItems.count))
            return TrendPoint(date: day, value: avg)
        }
    }
}


