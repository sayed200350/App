import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @State private var patterns: [Pattern] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ResilienceRing(score: analyticsManager.currentResilienceScore)
                    WeeklyStatsCard(stats: analyticsManager.weeklyStats)
                    if !patterns.isEmpty {
                        PatternAlertsCard(patterns: patterns)
                    }
                    RecoveryTrendsChart(points: analyticsManager.recoveryTrend)
                }
                .padding()
            }
            .navigationTitle("Your Resilience")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Timeframe", selection: $analyticsManager.timeframe) {
                        ForEach(TimeFrame.allCases) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .onChange(of: analyticsManager.timeframe) { _ in analyticsManager.recalculate() }
                }
            }
            .onAppear {
                analyticsManager.recalculate()
                patterns = PatternAnalyzer.shared.analyzePatterns(for: RejectionManager.shared.recent(days: analyticsManager.timeframe.days))
            }
        }
        .background(Color.resilientBackground.ignoresSafeArea())
    }
}
struct PatternAlertsCard: View {
    let patterns: [Pattern]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pattern Recognition")
                .font(.headline)
            ForEach(patterns) { p in
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.title).font(.subheadline).bold()
                    Text(p.description).font(.caption)
                    Text("Insight: \(p.insight)").font(.caption2)
                    Text("Action: \(p.actionable)").font(.caption2)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Pattern recognition alerts"))
    }
}


struct ResilienceRing: View {
    let score: Double

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: max(0.05, score / 100))
                    .stroke(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(score))")
                    .font(.largeTitle).bold()
            }
            Text("Resilience Score")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resilience score")
        .accessibilityValue("\(Int(score)) out of 100")
    }
}

struct WeeklyStatsCard: View {
    let stats: WeeklyStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week's Reality")
                .font(.headline)
            HStack {
                StatBlock(title: "Logs", value: "\(stats.totalLogs)")
                StatBlock(title: "High Impact", value: "\(stats.highImpact)")
                StatBlock(title: "Avg Impact", value: String(format: "%.1f", stats.averageImpact))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatBlock: View {
    let title: String
    let value: String
    var body: some View {
        VStack {
            Text(value).font(.title2).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AnalyticsManager())
    }
}


