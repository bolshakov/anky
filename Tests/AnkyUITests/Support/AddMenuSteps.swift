// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Opens Today's (+) menu and returns the item with that id once it shows, for the caller to tap.
@MainActor
func addMenuItem(_ id: String, in app: XCUIApplication) -> XCUIElement {
    let menu = app.buttons["add-menu"]
    XCTAssertTrue(menu.waitForExistence(timeout: 10))
    menu.tap()
    let item = app.buttons[id]
    XCTAssertTrue(item.waitForExistence(timeout: 10))
    return item
}
