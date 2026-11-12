// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class EmptyStateMarkTests: XCTestCase {
    func testFirstLaunchShowsMark() {
        continueAfterFailure = false
        let app = launchAnky()

        XCTAssertTrue(app.staticTexts["empty-today"].waitForExistence(timeout: 10))
        let today = app.descendants(matching: .any)["today-screen"]
        XCTAssertEqual(today.images.count, 0)
        attachScreenshot(named: "empty-state-mark")
    }
}
