import SwiftUI
import Charts

struct RecoveryTrendsChart: View {
    let points: [TrendPoint]

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                ChartView(points: points)
            } else {
                FallbackView(points: points)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

@available(iOS 16.0, *)
private struct ChartView: View {
    let points: [TrendPoint]
    var body: some View {
        Charts.Chart(points) { p in
            Charts.LineMark(x: .value("Date", p.date), y: .value("Impact", p.value))
        }
        .chartYScale(domain: 0...10)
    }
}

private struct FallbackView: View {
    let points: [TrendPoint]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recovery Trend (Avg Impact)").font(.headline)
            HStack(spacing: 2) {
                ForEach(points) { p in
                    Rectangle()
                        .fill(Color.resilientSecondary)
                        .frame(width: 6, height: max(4, CGFloat(p.value) * 8))
                }
            }
        }
    }
}


