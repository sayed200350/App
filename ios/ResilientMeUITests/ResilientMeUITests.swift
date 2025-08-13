import XCTest

final class ResilientMeUITests: XCTestCase {
    func testQuickLogFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Dismiss age gate if present
        if app.buttons["I am 18+"].exists { app.buttons["I am 18+"].tap() }

        app.tabBars.buttons["Quick Log"].tap()
        app.sliders.element.adjust(toNormalizedSliderPosition: 0.6)
        let logButton = app.buttons["Log Rejection"]
        if logButton.exists { logButton.tap() }
        sleep(1)
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].exists)
    }

    func testCommunityTabVisible() throws {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["I am 18+"].exists { app.buttons["I am 18+"].tap() }
        XCTAssertTrue(app.tabBars.buttons["Community"].exists)
    }
}


