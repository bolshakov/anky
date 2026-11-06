// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class DesignGalleryTests: XCTestCase {
    private let extraSmallText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXS"]

    func testGalleryOpensInPlaceOfToday() {
        continueAfterFailure = false
        let app = openGallery()

        XCTAssertTrue(app.descendants(matching: .any)["design-gallery"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["log-entry"].exists)
    }

    func testAppOpensOnTodayWithoutTheGalleryVariable() {
        continueAfterFailure = false
        let app = launchAnky()

        XCTAssertTrue(app.buttons["log-entry"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["design-gallery"].exists)
    }

    func testFirstBlockSpansTheScreenMarginsBelowTheBar() {
        continueAfterFailure = false
        let app = openGallery()
        let kind = app.segmentedControls["gallery-kind"]
        XCTAssertTrue(kind.waitForExistence(timeout: 10))

        let screen = app.windows.firstMatch.frame
        XCTAssertEqual(kind.frame.minX, 16, accuracy: 1)
        XCTAssertEqual(kind.frame.maxX, screen.maxX - 16, accuracy: 1)
        XCTAssertEqual(kind.frame.minY - app.navigationBars.firstMatch.frame.maxY, 16, accuracy: 1)
    }

    func testPillsSitSideBySideAnInlineGapApart() {
        continueAfterFailure = false
        let app = openGallery()
        let left = app.staticTexts["gallery-pill-left"]
        let right = app.staticTexts["gallery-pill-right"]
        XCTAssertTrue(left.waitForExistence(timeout: 10))

        XCTAssertEqual(left.frame.minX, 16, accuracy: 1)
        XCTAssertEqual(right.frame.minX - left.frame.maxX, 8, accuracy: 1)
    }

    func testSelectorChangesItsSelection() {
        continueAfterFailure = false
        let app = openGallery()
        let third = app.segmentedControls["gallery-kind"].buttons["Third"]
        XCTAssertTrue(third.waitForExistence(timeout: 10))

        third.tap()

        XCTAssertTrue(third.isSelected)
    }

    func testRowIsFiftyTwoPointsAtTheDefaultSize() {
        continueAfterFailure = false
        let row = plainRow(in: openGallery())

        XCTAssertEqual(row.frame.height, 52, accuracy: 1)
    }

    func testRowGrowsWithTheLargestText() {
        continueAfterFailure = false
        let row = plainRow(in: openGallery(arguments: largestTextArguments))

        XCTAssertGreaterThan(row.frame.height, 52)
    }

    func testRowIsNeverUnderFortyFourPoints() {
        continueAfterFailure = false
        let row = plainRow(in: openGallery(arguments: extraSmallText))

        XCTAssertGreaterThanOrEqual(row.frame.height, 44)
    }

    private func openGallery(arguments: [String] = []) -> XCUIApplication {
        launchAnky(arguments: arguments, environment: ["ANKY_DESIGN_GALLERY": "1"])
    }

    private func plainRow(in app: XCUIApplication) -> XCUIElement {
        let row = app.staticTexts["gallery-plain-row"]
        for _ in 0 ..< 5 where !row.exists {
            app.swipeUp()
        }
        XCTAssertTrue(row.exists)
        return row
    }
}
