import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseFirestoreSwift
#endif

final class FirestoreSyncService {
    static let shared = FirestoreSyncService()
    private init() {}

    func sync(entry: RejectionEntry) {
        #if canImport(FirebaseFirestore)
        guard FirebaseManager.shared.isConfigured else { return }
        guard let uid = FirebaseManager.shared.currentUser?.uid else { return }
        let db = Firestore.firestore()
        let doc = db.collection("users").document(uid).collection("rejections").document(entry.id.uuidString)

        let payload: [String: Any] = [
            "id": entry.id.uuidString,
            "type": entry.type.rawValue,
            "emotionalImpact": entry.emotionalImpact,
            "note": entry.note as Any,
            "timestamp": Timestamp(date: entry.timestamp)
        ]
        doc.setData(payload, merge: true) { error in
            if let error = error { print("[Firestore] Sync error: \(error)") }
        }
        #endif
    }
}


