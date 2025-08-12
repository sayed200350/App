import SwiftUI

struct RejectionLogView: View {
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @State private var rejectionType: RejectionType = .dating
    @State private var emotionalImpact: Double = 5
    @State private var note: String = ""
    @State private var isSaving: Bool = false
    @State private var image: UIImage? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(RejectionType.allCases) { type in
                        Button(action: { rejectionType = type }) {
                            Text(type.rawValue)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(rejectionType == type ? Color.orange : Color(.systemGray6))
                                .foregroundColor(rejectionType == type ? .white : .primary)
                                .cornerRadius(12)
                        }
                        .accessibilityLabel(Text(type.accessibilityTitle))
                        .accessibilityAddTraits(rejectionType == type ? .isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How much did this hurt? \(Int(emotionalImpact))/10").font(.subheadline)
                        Spacer()
                        Text(emoji(for: emotionalImpact)).font(.title2)
                    }
                    Slider(value: $emotionalImpact, in: 1...10, step: 1)
                        .tint(.orange)
                        .accessibilityLabel("Emotional impact")
                        .accessibilityValue("\(Int(emotionalImpact)) out of 10")
                }

                TextField("Quick note (optional)", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Note")

                ImagePickerView(image: $image)

                ResilientButton(title: isSaving ? "Logging..." : "Log Rejection", style: .primary, action: logRejection)
                .disabled(isSaving)
                .accessibilityLabel(isSaving ? "Logging" : "Log rejection")

                Spacer()
            }
            .padding()
            .navigationTitle("Quick Log")
        }
        .background(Color.resilientBackground.ignoresSafeArea())
    }

    private func logRejection() {
        isSaving = true
        let entry = RejectionEntry(
            id: UUID(),
            type: rejectionType,
            emotionalImpact: emotionalImpact,
            note: note.isEmpty ? nil : note,
            timestamp: Date()
        )
        RejectionManager.shared.save(entry: entry)
        analyticsManager.trackRejectionLogged(type: rejectionType)
        if let image = image {
            Task {
                let path = "rejection_images/\(FirebaseManager.shared.currentUser?.uid ?? "local")/\(entry.id).jpg"
                if let url = try? await ImageUploadService.shared.uploadImage(image, path: path) {
                    FirestoreSyncService.shared.attachImage(entryId: entry.id, imageUrl: url)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isSaving = false
            note = ""
            emotionalImpact = 5
            image = nil
        }
    }

    private func emoji(for value: Double) -> String {
        switch Int(value) {
        case 1...3: return "🙂"
        case 4...6: return "😕"
        case 7...8: return "😢"
        default: return "😭"
        }
    }
}

struct RejectionLogView_Previews: PreviewProvider {
    static var previews: some View {
        RejectionLogView()
            .environmentObject(AnalyticsManager())
    }
}


