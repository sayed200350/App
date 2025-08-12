import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

struct CommunityStory: Identifiable, Codable {
    let id: String
    let type: RejectionType
    let content: String
    let createdAt: Date
    var reactions: [Reaction: Int]
    var userReaction: Reaction?

    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}

final class CommunityManager: ObservableObject {
    @Published private(set) var stories: [CommunityStory] = []

    func loadStories() async {
        #if canImport(FirebaseFirestore)
        guard FirebaseManager.shared.isConfigured else { return }
        let db = Firestore.firestore()
        let snapshot = try? await db.collection("community").order(by: "createdAt", descending: true).limit(to: 100).getDocuments()
        let list: [CommunityStory] = snapshot?.documents.compactMap { doc in
            let data = doc.data()
            guard let typeRaw = data["type"] as? String,
                  let type = RejectionType(rawValue: typeRaw),
                  let content = data["content"] as? String,
                  let ts = data["createdAt"] as? Timestamp else { return nil }
            let reactionsMap = data["reactions"] as? [String: Int] ?? [:]
            var reactions: [Reaction: Int] = [:]
            reactionsMap.forEach { key, value in if let r = Reaction(rawValue: key) { reactions[r] = value } }
            return CommunityStory(id: doc.documentID, type: type, content: content, createdAt: ts.dateValue(), reactions: reactions, userReaction: nil)
        } ?? []
        await MainActor.run { self.stories = list }
        #endif
    }

    func getStories(filter: RejectionType?) -> [CommunityStory] {
        guard let filter = filter else { return stories }
        return stories.filter { $0.type == filter }
    }

    func addReaction(to story: CommunityStory, reaction: Reaction) {
        #if canImport(FirebaseFirestore)
        guard FirebaseManager.shared.isConfigured else { return }
        let db = Firestore.firestore()
        let ref = db.collection("community").document(story.id)
        let key = reaction.rawValue
        ref.setData(["reactions.\(key)": FieldValue.increment(Int64(1))], merge: true)
        #endif
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("reaction_add", parameters: ["reaction": reaction.rawValue])
        #endif
    }

    func submitStory(type: RejectionType, content: String) async throws {
        #if canImport(FirebaseFirestore)
        guard FirebaseManager.shared.isConfigured else { return }
        let db = Firestore.firestore()
        let payload: [String: Any] = [
            "type": type.rawValue,
            "content": content,
            "createdAt": Timestamp(date: Date()),
            "reactions": [:],
            "authorUid": FirebaseManager.shared.currentUser?.uid as Any
        ]
        _ = try await db.collection("community").addDocument(data: payload)
        #endif
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("community_post", parameters: ["type": type.rawValue])
        #endif
    }
}


