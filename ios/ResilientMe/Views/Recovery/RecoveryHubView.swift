import SwiftUI

struct RecoveryHubView: View {
    @State private var last: RejectionEntry? = RejectionManager.shared.recent(days: 30).first

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let rejection = last {
                        RecoveryPlanCard(rejectionType: rejection.type)
                        QuickRecoveryActions(rejectionType: rejection.type)
                    } else {
                        Text("No recent rejections. Log one to get a tailored recovery plan.")
                            .font(.resilientBody)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Recovery Hub")
            .onAppear { last = RejectionManager.shared.recent(days: 30).first }
        }
        .background(Color.resilientBackground.ignoresSafeArea())
        .onAppear { AnalyticsManager.trackScreenView("Recovery") }
    }
}

struct RecoveryPlanCard: View {
    let rejectionType: RejectionType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.resilientHeadline)
            Text(description).font(.resilientBody).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("5-Minute Recovery Plan:").font(.subheadline).bold()
                ForEach(steps, id: \.self) { step in
                    HStack {
                        Image(systemName: "checkmark.circle").foregroundColor(.green)
                        Text(step).font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var title: String {
        switch rejectionType {
        case .dating: return "Ghosted Again? You're Not Alone"
        case .job: return "Another 'No'? Let's Rebuild Your Confidence"
        case .social: return "Awkward Moment? Everyone Has Them"
        case .academic: return "Rejection Builds Character"
        case .other: return "This Too Shall Pass"
        }
    }

    private var description: String {
        switch rejectionType {
        case .dating: return "Dating apps can be brutal. This is about fit, not your worth."
        case .job: return "The market is tough; you're gaining momentum with each try."
        default: return "You're building resilience with every step."
        }
    }

    private var steps: [String] {
        switch rejectionType {
        case .dating:
            return [
                "Take 3 deep breaths - this is about them, not you",
                "Text a friend who makes you laugh",
                "Do one thing that makes you feel good about yourself"
            ]
        case .job:
            return [
                "Remember the averages favor persistence",
                "Update your application tracker",
                "Apply to 2 more positions today"
            ]
        default:
            return [
                "Acknowledge the feeling without judgment",
                "Put it in perspective",
                "Do something kind for yourself"
            ]
        }
    }
}

struct QuickRecoveryActions: View {
    let rejectionType: RejectionType
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions").font(.resilientHeadline)
            HStack {
                ResilientButton(title: "Breathe", style: .secondary) {}
                ResilientButton(title: "Text a friend", style: .secondary) {}
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


