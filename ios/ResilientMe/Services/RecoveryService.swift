import Foundation
#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif

struct RecoveryPlanStep: Codable, Identifiable {
    var id: String { title }
    let title: String
    let detail: String
}

struct RecoveryPlan: Codable {
    let steps: [RecoveryPlanStep]
    let affirmations: [String]
    let templates: [Template]

    struct Template: Codable, Identifiable {
        var id: String { label }
        let label: String
        let text: String
    }
}

final class RecoveryService {
    #if canImport(FirebaseFunctions)
    private let functions = Functions.functions()
    #endif

    func generateRecoveryPlan(type: RejectionType, impact: Int, note: String?, tone: String = "gentle") async throws -> RecoveryPlan {
        #if canImport(FirebaseFunctions)
        let payload: [String: Any] = [
            "type": mapType(type),
            "impact": max(0, min(10, impact)),
            "note": (note ?? "").prefix(2000),
            "tone": tone
        ]
        let call = functions.httpsCallable("generateRecoveryPlan")
        let result = try await call.call(payload)
        guard let dict = result.data as? [String: Any] else {
            throw NSError(domain: "RecoveryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        let plan = try JSONDecoder().decode(RecoveryPlan.self, from: data)
        return plan
        #else
        throw NSError(domain: "RecoveryService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Functions not available"])
        #endif
    }

    private func mapType(_ type: RejectionType) -> String {
        switch type {
        case .dating: return "dating"
        case .job: return "job"
        case .social: return "social"
        case .academic: return "academic"
        case .other: return "other"
        }
    }
}