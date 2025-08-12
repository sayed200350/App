import SwiftUI

struct HistoryView: View {
    @State private var entries: [RejectionEntry] = []

    var body: some View {
        NavigationView {
            AuthGate {
                List(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.type.rawValue)
                        .font(.headline)
                    HStack {
                        Text("Impact: \(Int(entry.emotionalImpact)) / 10")
                        Spacer()
                        Text(entry.timestamp, style: .date)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    if let note = entry.note, !note.isEmpty {
                        Text(note).font(.subheadline)
                    }
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("\(entry.type.accessibilityTitle) rejection"))
                .accessibilityValue(Text("Impact \(Int(entry.emotionalImpact)) out of 10 on \(entry.timestamp.formatted(date: .abbreviated, time: .omitted))"))
                }
            }
            .navigationTitle("History")
            .onAppear { entries = RejectionManager.shared.recent(days: 30) }
        }
        .background(Color.resilientBackground.ignoresSafeArea())
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}


