// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LogDoseCheckInTests: XCTestCase {
    func testSwitchFollowsTheSelectedMedicationsSavedDelay() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        addMedication(named: "Zorblex", app)
        addMedication(named: "Quibbanol", delay: "1 hour", app)
        expectCheckIn(on: true, delay: "1 hour", app)

        medicationRow(startingWith: "Zorblex", in: app).tap()
        expectCheckIn(on: false, delay: nil, app)

        medicationRow(startingWith: "Quibbanol", in: app).tap()
        expectCheckIn(on: true, delay: "1 hour", app)
    }

    /// Adds from the Add medication row of the open Log Dose sheet, which stays open after each save.
    private func addMedication(named name: String, delay: String? = nil, _ app: XCUIApplication) {
        app.buttons["dose-add-medication"].tap()
        let field = app.textFields["medication-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        if let delay {
            chooseCheckInAfter(delay, in: app)
        }
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.buttons["dose-add-medication"].waitForExistence(timeout: 10))
    }

    private func chooseCheckInAfter(_ delay: String, in app: XCUIApplication) {
        let row = app.descendants(matching: .any).matching(identifier: "check-in-after").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where row.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        row.tap()
        let item = app.buttons[delay]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(delay)")
        item.tap()
    }

    private func medicationRow(startingWith name: String, in app: XCUIApplication) -> XCUIElement {
        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@ AND label BEGINSWITH %@", "dose-medication-row", name)
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "no medication row for \(name)")
        return row
    }

    /// The switch reads '1' or '0', and the menu is shown only while the switch is on, with its delay as its value.
    private func expectCheckIn(on: Bool, delay: String?, _ app: XCUIApplication) {
        let toggle = app.descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, on ? "1" : "0")
        let menu = app.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
        if let delay {
            XCTAssertTrue(menu.waitForExistence(timeout: 10))
            XCTAssertEqual(menu.value as? String, delay)
        } else {
            XCTAssertTrue(menu.waitForNonExistence(timeout: 10))
        }
    }
}
