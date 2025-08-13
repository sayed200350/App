import Foundation

enum Reaction: String, CaseIterable, Codable, Hashable {
    case support = "💪"
    case relate = "😔"
    case celebrate = "🎉"
    case hug = "🫂"

    var accessibilityLabel: String {
        switch self {
        case .support: return "Support"
        case .relate: return "Relate"
        case .celebrate: return "Celebrate"
        case .hug: return "Hug"
        }
    }
}


