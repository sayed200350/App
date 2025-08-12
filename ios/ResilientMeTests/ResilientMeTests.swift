import XCTest
@testable import ResilientMe

final class ResilientMeTests: XCTestCase {
    func testRejectionSaveAndFetch() {
        let entry = RejectionEntry(id: UUID(), type: .dating, emotionalImpact: 7, note: "ghosted", timestamp: Date())
        RejectionManager.shared.save(entry: entry)
        let recent = RejectionManager.shared.recent(days: 1)
        XCTAssertTrue(recent.contains { $0.id == entry.id })
    }

    func testPatternAnalyzerGhosting() {
        let now = Date()
        let list = (0..<4).map { i in RejectionEntry(id: UUID(), type: .dating, emotionalImpact: 6, note: i < 3 ? "ghost" : "", timestamp: now.addingTimeInterval(Double(i) * -3600)) }
        let patterns = PatternAnalyzer.shared.analyzePatterns(for: list)
        XCTAssertTrue(patterns.contains { $0.title.contains("Ghosting") })
    }
}


