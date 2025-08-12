import Foundation

struct RejectionEntry: Identifiable {
    let id: UUID
    let type: RejectionType
    let emotionalImpact: Double
    let note: String?
    let timestamp: Date
}


