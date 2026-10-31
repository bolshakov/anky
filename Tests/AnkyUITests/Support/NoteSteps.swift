// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
func typeNote(_ text: String, in app: XCUIApplication) {
    let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
    for _ in 0 ..< 3 where !field.isHittable {
        app.swipeUp()
    }
    XCTAssertTrue(field.waitForExistence(timeout: 10))
    field.tap()
    field.typeText(text)
}
