import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseFirestoreSwift
#endif

protocol RejectionRepository {
    func save(entry: RejectionEntry)
}

final class FirestoreSyncService: RejectionRepository {
    static let shared = FirestoreSyncService()
    private init() {}

    private let queue = DispatchQueue(label: "com.resilientme.sync", qos: .utility)
    private var pending: [RejectionEntry] = []

    func save(entry: RejectionEntry) {
        // Enqueue and process in background
        queue.async { [weak self] in
            self?.pending.append(entry)
            self?.processQueue()
        }
    }

    private func processQueue() {
        #if canImport(FirebaseFirestore)
        guard FirebaseManager.shared.isConfigured else { return }
        guard let uid = FirebaseManager.shared.currentUser?.uid else { return }
        let db = Firestore.firestore()

        while !pending.isEmpty {
            let entry = pending.removeFirst()
            let doc = db.collection("users").document(uid).collection("rejections").document(entry.id.uuidString)
            let payload: [String: Any] = [
                "id": entry.id.uuidString,
                "type": entry.type.rawValue,
                "emotionalImpact": entry.emotionalImpact,
                "note": entry.note as Any,
                "timestamp": Timestamp(date: entry.timestamp)
            ]
            doc.setData(payload, merge: true) { error in
                if let error = error {
                    print("[Firestore] Sync error: \(error)")
                    // backoff requeue
                    self.queue.asyncAfter(deadline: .now() + 2.0) { [weak self] in self?.pending.insert(entry, at: 0) }
                }
            }
        }
        #endif
    }
}


