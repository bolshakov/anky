// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInDelayChoiceTests: XCTestCase {
    func testMenuListsTheSixChoicesInOrder() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(shownChoice(in: app), "Off")

        app.buttons["check-in-after"].tap()

        let titles = ["Off", "30 minutes", "1 hour", "2 hours", "3 hours", "4 hours"]
        let tops = titles.map { title -> CGFloat in
            let item = app.buttons[title]
            XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(title)")
            return item.frame.minY
        }
        XCTAssertEqual(tops, tops.sorted())
        XCTAssertEqual(Set(tops).count, titles.count)
    }

    func testChoosingTwoHoursShowsItAndSavesIt() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        choose("2 hours", in: app)
        XCTAssertEqual(shownChoice(in: app), "2 hours")

        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)
        scrollToCheckIn(in: app)
        XCTAssertEqual(shownChoice(in: app), "2 hours")
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
        XCTAssertEqual(shownChoice(in: relaunched), "1 hour")
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

        XCTAssertTrue(app.buttons["Off"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(shownChoice(in: app), "1 hour")
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
        XCTAssertEqual(shownChoice(in: app), "1 hour")
    }

    private func openLogDose(_ app: XCUIApplication) {
        app.buttons["log-medication"].tap()
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

    private func choose(_ option: String, in app: XCUIApplication) {
        scrollToCheckIn(in: app)
        app.buttons["check-in-after"].tap()
        let item = app.buttons[option]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(option)")
        item.tap()
        XCTAssertTrue(app.buttons["check-in-after"].waitForExistence(timeout: 10))
    }

    /// The system draws the chosen title as its own text inside the row, so the row's value is empty.
    private func shownChoice(in app: XCUIApplication) -> String? {
        let row = app.buttons["check-in-after"]
        guard row.exists else { return nil }
        let texts = app.staticTexts.allElementsBoundByIndex.filter { $0.frame.intersects(row.frame) }
        let titles = ["Off", "30 minutes", "1 hour", "2 hours", "3 hours", "4 hours"]
        return titles.first { title in texts.contains { $0.label == title } }
    }

    /// The pinned Save button covers the bottom of the form, so the row must scroll above it, not merely be on screen.
    private func scrollToCheckIn(in app: XCUIApplication) {
        let row = app.buttons["check-in-after"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where row.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        XCTAssertLessThanOrEqual(row.frame.maxY, save.frame.minY)
    }
}
