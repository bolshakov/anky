// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class SaveMedicationTests: XCTestCase {
    func testTwoQuickTapsOnSaveMakeOneMedication() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()

        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")

        let save = app.buttons["medication-save"]
        save.doubleTap()

        XCTAssertTrue(save.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["dose-add-medication"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "dose-medication-row").count, 1)
    }
}
