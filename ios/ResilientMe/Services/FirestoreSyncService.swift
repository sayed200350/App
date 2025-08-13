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
    private init() {
        loadPendingFromDisk()
    }

    private let queue = DispatchQueue(label: "com.resilientme.sync", qos: .utility)
    private var pending: [RejectionEntry] = [] { didSet { savePendingToDisk() } }
    private var retryDelay: TimeInterval = 1

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
            let semaphore = DispatchSemaphore(value: 0)
            var hadError = false
            doc.setData(payload, merge: true) { error in
                if let error = error {
                    print("[Firestore] Sync error: \(error)")
                    hadError = true
                }
                semaphore.signal()
            }
            semaphore.wait()
            if hadError {
                // backoff requeue and stop processing
                pending.insert(entry, at: 0)
                retryDelay = min(retryDelay * 2, 60)
                queue.asyncAfter(deadline: .now() + retryDelay) { [weak self] in self?.processQueue() }
                return
            } else {
                retryDelay = 1
            }
        }
        #endif
    }

    // MARK: - Persistence
    private func savePendingToDisk() {
        do {
            let data = try JSONEncoder().encode(pending)
            try data.write(to: pendingURL(), options: .atomic)
        } catch {
            print("[Sync] Failed to persist queue: \(error)")
        }
    }

    private func loadPendingFromDisk() {
        do {
            let url = pendingURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([RejectionEntry].self, from: data)
            pending = items
        } catch {
            print("[Sync] Failed to load queue: \(error)")
        }
    }

    private func pendingURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("sync_queue.json")
    }
}


