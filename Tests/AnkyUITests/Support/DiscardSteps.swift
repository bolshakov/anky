// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
func discardChanges(in app: XCUIApplication) {
    let discard = app.buttons["discard-changes"].firstMatch
    XCTAssertTrue(discard.waitForExistence(timeout: 10))
    discard.tap()
}
