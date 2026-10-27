import XCTest

@MainActor
final class EmptyStateMarkTests: XCTestCase {
    func testFirstLaunchShowsMark() {
        continueAfterFailure = false
        let app = launchAnky()

        XCTAssertTrue(app.staticTexts["Nothing logged today"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.images.count, 0)
        attachScreenshot(named: "empty-state-mark")
    }
}
