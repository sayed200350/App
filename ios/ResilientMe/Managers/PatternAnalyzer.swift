import Foundation

final class PatternAnalyzer: ObservableObject {
    static let shared = PatternAnalyzer()
    private init() {}

    func analyzePatterns(for rejections: [RejectionEntry]) -> [Pattern] {
        var patterns: [Pattern] = []

        if let ghost = detectGhostingPattern(rejections) { patterns.append(ghost) }
        if let day = detectDayOfWeekPattern(rejections) { patterns.append(day) }
        if let recovery = detectRecoveryImprovement(rejections) { patterns.append(recovery) }

        return patterns
    }

    private func detectGhostingPattern(_ rejections: [RejectionEntry]) -> Pattern? {
        let dating = rejections.filter { $0.type == .dating }
        let ghostCount = dating.filter { ($0.note ?? "").lowercased().contains("ghost") }.count
        guard ghostCount >= 3, ghostCount > max(1, dating.count / 2) else { return nil }
        return Pattern(
            title: "Ghosting Pattern Detected",
            description: "You've been ghosted \(ghostCount) times in the selected period",
            insight: "This is about their communication style, not your worth",
            actionable: "Try apps that require more investment upfront"
        )
    }

    private func detectDayOfWeekPattern(_ rejections: [RejectionEntry]) -> Pattern? {
        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for r in rejections {
            let day = calendar.component(.weekday, from: r.timestamp)
            counts[day, default: 0] += 1
        }
        guard let (day, count) = counts.max(by: { $0.value < $1.value }), count >= max(3, rejections.count / 3) else { return nil }
        let formatter = DateFormatter(); formatter.locale = .current; formatter.setLocalizedDateFormatFromTemplate("EEEE")
        let dayName = formatter.weekdaySymbols[(day - 1) % 7]
        return Pattern(
            title: "Timing Pattern",
            description: "Most rejections occur on \(dayName)",
            insight: "Consider adjusting outreach timing",
            actionable: "Avoid sending important messages on heavy days"
        )
    }

    private func detectRecoveryImprovement(_ rejections: [RejectionEntry]) -> Pattern? {
        let sorted = rejections.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 4 else { return nil }
        let impacts = sorted.map { $0.emotionalImpact }
        let firstHalfAvg = impacts.prefix(impacts.count / 2).reduce(0, +) / Double(max(1, impacts.count / 2))
        let secondHalfAvg = impacts.suffix(impacts.count / 2).reduce(0, +) / Double(max(1, impacts.count / 2))
        guard secondHalfAvg < firstHalfAvg - 1.0 else { return nil }
        return Pattern(
            title: "Recovery Improving",
            description: "Average impact decreased over time",
            insight: "You're building resilience",
            actionable: "Keep consistent with small daily actions"
        )
    }
}


