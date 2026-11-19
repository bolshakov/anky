// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// The date under Today's title, which is the navigation bar's subtitle and so has no identifier. It is the text in the
/// bar that is not the title, which is whatever words the title has in the language under test.
@MainActor
func todayDate(in app: XCUIApplication) -> XCUIElement {
    let title = app.navigationBars.firstMatch.staticTexts.element(boundBy: 0).label
    return app.navigationBars.firstMatch.staticTexts.matching(NSPredicate(format: "label != %@", title)).firstMatch
}
