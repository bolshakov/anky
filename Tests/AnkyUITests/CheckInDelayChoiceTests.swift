// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInDelayChoiceTests: XCTestCase {
    func testSwitchStartsOffWithItsFootnoteAskingToTurnItOn() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(checkInSwitch(in: app).value as? String, "0")
        XCTAssertFalse(menu(in: app).exists)
        XCTAssertEqual(
            footnote(in: app).label,
            "Anky asks how your pain is after this long. Turn it on to choose a time."
        )
    }

    func testTurningTheSwitchOnShowsTwoHoursAndTheFiveDelaysInOrder() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        turnOn(in: app)
        XCTAssertEqual(menu(in: app).value as? String, "2 hours")
        XCTAssertEqual(footnote(in: app).label, "Anky asks how your pain is after this long.")

        menu(in: app).tap()
        let titles = ["30 minutes", "1 hour", "2 hours", "3 hours", "4 hours"]
        let tops = titles.map { title -> CGFloat in
            let item = app.buttons[title]
            XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(title)")
            return item.frame.minY
        }
        XCTAssertEqual(tops, tops.sorted())
        XCTAssertEqual(Set(tops).count, titles.count)
        XCTAssertFalse(app.buttons["Off"].exists)
    }

    func testWholeMenuRowOpensTheMenu() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        turnOn(in: app)
        let row = menu(in: app)
        XCTAssertGreaterThanOrEqual(row.frame.height, 44)
        for dx in [0.1, 0.5, 0.9] {
            row.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: 0.5)).tap()
            XCTAssertTrue(app.buttons["30 minutes"].waitForExistence(timeout: 10), "no menu from dx \(dx)")
            app.buttons["30 minutes"].tap()
            XCTAssertTrue(app.buttons["30 minutes"].waitForNonExistence(timeout: 10))
        }
    }

    func testAfterLabelOpensTheMenuWhenTheValueStacksAtLargestSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewMedication(app)
        choose("30 minutes", in: app)
        scrollToCheckIn(in: app)
        let row = menu(in: app)
        XCTAssertGreaterThanOrEqual(row.frame.height, 44)
        XCTAssertGreaterThan(row.frame.height, 120, "the value should stack under After at this size")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.2)).tap()
        XCTAssertTrue(app.buttons["1 hour"].waitForExistence(timeout: 10), "no menu beside After")
    }

    func testChoosingTwoHoursShowsItAndSavesIt() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        choose("2 hours", in: app)
        XCTAssertEqual(menu(in: app).value as? String, "2 hours")

        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(menu(in: app).value as? String, "2 hours")
    }

    func testSwitchingOffAfterAChoiceSavesNoDelay() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        choose("1 hour", in: app)
        scrollToCheckIn(in: app)
        checkInSwitch(in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertTrue(menu(in: app).waitForNonExistence(timeout: 10))

        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(checkInSwitch(in: app).value as? String, "0")
    }

    func testMedicationSavedWithOneHourReopensOnOneHour() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        openNewMedication(app)
        choose("1 hour", in: app)
        saveNewMedication(named: "Zorblex", app)
        app.terminate()

        let relaunched = launchAnky(folder: folder)
        openLogDose(relaunched)
        openMedicationsFromLogDose(relaunched)
        openMedicationFromList(relaunched)
        scrollToCheckIn(in: relaunched)
        XCTAssertEqual(menu(in: relaunched).value as? String, "1 hour")
    }

    func testChoosingTheChosenValueClosesTheMenuAndKeepsTheRow() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        choose("1 hour", in: app)
        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)

        choose("1 hour", in: app)

        XCTAssertTrue(app.buttons["30 minutes"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(menu(in: app).value as? String, "1 hour")
    }

    func testCancelAfterChangingKeepsTheSavedDelay() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        choose("1 hour", in: app)
        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)

        choose("3 hours", in: app)
        app.buttons["medication-cancel"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        openMedicationFromList(app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(menu(in: app).value as? String, "1 hour")
    }

    private func openLogDose(_ app: XCUIApplication) {
        tapLogMedication(in: app)
        XCTAssertTrue(app.buttons["dose-add-medication"].waitForExistence(timeout: 10))
    }

    private func openNewMedication(_ app: XCUIApplication) {
        openLogDose(app)
        app.buttons["dose-add-medication"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    private func openMedicationsFromLogDose(_ app: XCUIApplication) {
        app.buttons["log-dose-manage"].tap()
        XCTAssertTrue(app.buttons["medications-add"].waitForExistence(timeout: 10))
    }

    private func openMedicationFromList(_ app: XCUIApplication) {
        app.buttons["medication-row"].firstMatch.tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
    }

    private func saveNewMedication(named name: String, _ app: XCUIApplication) {
        let field = app.textFields["medication-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 10))
    }

    /// Makes the switch on when it is off, then picks the option from the menu.
    private func choose(_ option: String, in app: XCUIApplication) {
        if checkInSwitch(in: app).value as? String == "0" {
            turnOn(in: app)
        } else {
            scrollToCheckIn(in: app)
        }
        menu(in: app).tap()
        let item = app.buttons[option]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(option)")
        item.tap()
        XCTAssertTrue(menu(in: app).waitForExistence(timeout: 10))
    }

    private func turnOn(in app: XCUIApplication) {
        scrollToCheckIn(in: app)
        checkInSwitch(in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertTrue(menu(in: app).waitForExistence(timeout: 10), "no menu after the switch went on")
    }

    private func form(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
    }

    private func checkInSwitch(in app: XCUIApplication) -> XCUIElement {
        form(in: app).descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
    }

    private func menu(in app: XCUIApplication) -> XCUIElement {
        form(in: app).descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
    }

    private func footnote(in app: XCUIApplication) -> XCUIElement {
        let text = form(in: app).descendants(matching: .any).matching(identifier: "check-in-footnote").firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 10))
        return text
    }

    /// The pinned Save button covers the bottom of the form, so the card must scroll above it, not merely be on screen.
    /// The last row of the card is the menu when it shows, and the switch when it does not.
    private func scrollToCheckIn(in app: XCUIApplication) {
        let anchor = menu(in: app).exists ? menu(in: app) : checkInSwitch(in: app)
        XCTAssertTrue(anchor.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where anchor.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        XCTAssertLessThanOrEqual(anchor.frame.maxY, save.frame.minY)
    }
}
