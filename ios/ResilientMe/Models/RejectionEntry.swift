import Foundation

struct RejectionEntry: Identifiable, Codable {
    let id: UUID
    let type: RejectionType
    let emotionalImpact: Double
    let note: String?
    let timestamp: Date
    var imageUrl: String?
}


