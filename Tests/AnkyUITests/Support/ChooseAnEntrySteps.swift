// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
func chooseAnEntryBar(_ app: XCUIApplication) -> XCUIElement {
    app.navigationBars["Choose an Entry"]
}

@MainActor
func goBackFromChooseAnEntry(_ app: XCUIApplication) {
    chooseAnEntryBar(app).buttons.element(boundBy: 0).tap()
}
