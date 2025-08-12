import Foundation

enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}


