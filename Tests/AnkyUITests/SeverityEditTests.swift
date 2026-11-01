// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class SeverityEditTests: XCTestCase {
    func testAnOpenedEntryShowsItsOwnLevelNotTheLastSaved() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        setSeverity(2, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        openNewEntry(app)
        app.buttons["kind-stiffness"].tap()
        setSeverity(7, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        let painRow = app.descendants(matching: .any)["entry-row-pain"]
        XCTAssertTrue(painRow.waitForExistence(timeout: 10))
        painRow.tap()

        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        XCTAssertEqual(severityLevel(of: slider), 2)
    }
}
