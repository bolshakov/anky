// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LargeTextTests: XCTestCase {
    func testSaveStaysPinnedAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewEntry(app)

        let save = app.buttons["save-entry"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        let pinned = save.frame
        XCTAssertGreaterThanOrEqual(pinned.height, 44)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(pinned))
        attachScreenshot(named: "large-text-top")

        scrollToNoteField(in: app)
        XCTAssertEqual(save.frame, pinned)
        XCTAssertTrue(save.isHittable)
        attachScreenshot(named: "large-text-scrolled")
    }
}
