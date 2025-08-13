import SwiftUI

struct ResponseTemplate: Identifiable {
    let id = UUID()
    let title: String
    let scenario: String
    let template: String
    let tone: String
}

struct ResponseTemplatesView: View {
    let rejectionType: RejectionType
    @State private var selected: ResponseTemplate?

    var body: some View {
        List(templates) { tpl in
            VStack(alignment: .leading, spacing: 6) {
                Text(tpl.title).font(.headline)
                Text(tpl.scenario).font(.caption).foregroundColor(.secondary)
                Text("Tone: \(tpl.tone)").font(.caption2).foregroundColor(.secondary)
            }
            .onTapGesture { selected = tpl }
        }
        .navigationTitle("Response Templates")
        .sheet(item: $selected) { t in
            VStack(alignment: .leading, spacing: 12) {
                Text(t.title).font(.title3).bold()
                Text(t.template).font(.body)
                Spacer()
                ResilientButton(title: "Copy", style: .primary) {
                    UIPasteboard.general.string = t.template
                }
            }
            .padding()
        }
    }

    private var templates: [ResponseTemplate] {
        switch rejectionType {
        case .dating:
            return [
                ResponseTemplate(title: "After Being Ghosted", scenario: "No reply after chats", template: "Hey, I know life gets busy. If you're not into this, no hard feelings. Wishing you well!", tone: "Graceful exit"),
                ResponseTemplate(title: "Direct Rejection", scenario: "They said they're not interested", template: "Thanks for being honest. I appreciate it and wish you the best!", tone: "Mature response")
            ]
        case .job:
            return [
                ResponseTemplate(title: "Following Up", scenario: "No response after applying", template: "Hi [Name], checking on my application for [Role]. I'm still very interested and would love to share more about my fit. Thanks for your time!", tone: "Professional persistence"),
                ResponseTemplate(title: "Rejection Reply", scenario: "Got a rejection email", template: "Thank you for the update. I appreciate the opportunity. Please keep me in mind for future roles. Best to your team!", tone: "Professional grace")
            ]
        default:
            return [
                ResponseTemplate(title: "Social Decline", scenario: "Plans fall through", template: "No worries at all—maybe next time! Take care ✌️", tone: "Friendly")
            ]
        }
    }
}