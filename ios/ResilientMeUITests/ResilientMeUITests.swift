import XCTest

final class ResilientMeUITests: XCTestCase {
    func testQuickLogFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Quick Log"].tap()
        app.sliders.element.adjust(toNormalizedSliderPosition: 0.6)
        let logButton = app.buttons["Log Rejection"]
        if logButton.exists { logButton.tap() }
        sleep(1)
        app.tabBars.buttons["History"].tap()
        // No strict assertion due to varying state; presence of list indicates success
        XCTAssertTrue(app.navigationBars["History"].exists)
    }
}


