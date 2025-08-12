import Foundation

public enum RejectionType: String, CaseIterable, Identifiable, Codable {
    case dating = "💔 Dating"
    case job = "💼 Job"
    case social = "👥 Social"
    case academic = "📚 Academic"
    case other = "😔 Other"

    public var id: String { rawValue }
    public var displayTitle: String { rawValue }

    public var accessibilityTitle: String {
        switch self {
        case .dating: return "Dating"
        case .job: return "Job"
        case .social: return "Social"
        case .academic: return "Academic"
        case .other: return "Other"
        }
    }
}


