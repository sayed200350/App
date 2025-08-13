import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct HistoryView: View {
    @State private var entries: [RejectionEntry] = []
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            AuthGate {
                if let error = errorMessage {
                    Text(error).font(.footnote).foregroundColor(.white).padding(8).frame(maxWidth: .infinity).background(Color.red.opacity(0.8)).cornerRadius(8).padding([.horizontal, .top])
                }
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Text("No logs yet.").font(.resilientHeadline)
                        Text("Your story starts when you log your first rejection.").font(.resilientBody).foregroundColor(.secondary)
                        ResilientButton(title: "Log one now", style: .primary) { }
                    }
                    .resilientCard()
                    .padding()
                } else {
                    List(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 12) {
                            if let url = entry.imageUrl, let u = URL(string: url) {
                                AsyncImage(url: u) { phase in
                                    switch phase {
                                    case .empty: ProgressView().frame(width: 54, height: 54)
                                    case .success(let img): img.resizable().scaledToFill().frame(width: 54, height: 54).clipped().cornerRadius(8)
                                    case .failure: Image(systemName: "photo").frame(width: 54, height: 54)
                                    @unknown default: EmptyView()
                                    }
                                }
                            }
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
                        }
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(entry.type.accessibilityTitle) rejection"))
                    .accessibilityValue(Text("Impact \(Int(entry.emotionalImpact)) out of 10 on \(entry.timestamp.formatted(date: .abbreviated, time: .omitted))"))
                    .swipeActions {
                        Button(role: .destructive) { delete(entry: entry) } label: { Label("Delete", systemImage: "trash") }
                    }
                    }
                }
            }
            .navigationTitle("History")
            .onAppear { AnalyticsManager.trackScreenView("History"); loadHistory() }
        }
        .background(Color.resilientBackground.ignoresSafeArea())
    }

    private func loadHistory() {
        #if canImport(FirebaseFirestore)
        if FirebaseManager.shared.isConfigured, let uid = FirebaseManager.shared.currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(uid).collection("rejections").order(by: "timestamp", descending: true).limit(to: 50).getDocuments { snap, err in
                if let err = err { self.errorMessage = err.localizedDescription; return }
                if let docs = snap?.documents {
                    let mapped: [RejectionEntry] = docs.compactMap { d in
                        let data = d.data()
                        guard let typeRaw = data["type"] as? String,
                              let type = RejectionType(rawValue: typeRaw),
                              let impact = data["emotionalImpact"] as? Double,
                              let ts = data["timestamp"] as? Timestamp else { return nil }
                        let note = data["note"] as? String
                        return RejectionEntry(id: UUID(uuidString: d.documentID) ?? UUID(), type: type, emotionalImpact: impact, note: note, timestamp: ts.dateValue(), imageUrl: data["imageUrl"] as? String)
                    }
                    self.entries = mapped
                } else {
                    self.entries = RejectionManager.shared.recent(days: 30)
                }
            }
            return
        }
        #endif
        entries = RejectionManager.shared.recent(days: 30)
    }

    private func delete(entry: RejectionEntry) {
        #if canImport(FirebaseFirestore)
        if FirebaseManager.shared.isConfigured, let uid = FirebaseManager.shared.currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(uid).collection("rejections").document(entry.id.uuidString).delete { _ in
                RejectionManager.shared.delete(id: entry.id)
                loadHistory()
            }
            return
        }
        #endif
        RejectionManager.shared.delete(id: entry.id)
        loadHistory()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}


