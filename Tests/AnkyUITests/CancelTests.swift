// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CancelTests: XCTestCase {
    func testCancelUnchangedClosesAtOnce() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(6, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))

        openNewEntry(app)
        app.buttons["cancel-entry"].tap()

        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(app.sheets.count, 0)
        XCTAssertEqual(entryRows(in: app).count, 1)
        attachScreenshot(named: "cancel-saves-nothing")
    }

    func testCancelAfterChangeAsksAndDiscardSavesNothing() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(1, in: app)
        app.buttons["cancel-entry"].tap()

        XCTAssertTrue(app.buttons["discard-changes"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 2))
        attachScreenshot(named: "cancel-after-change")

        discardChanges(in: app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 0)
    }

    func testCancelKeepsWorkingAfterTheDialogIsDismissedByATapOutside() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(1, in: app)

        askAndDismissByTapOutside(cancel: app.buttons["cancel-entry"], in: app)

        assertStillOpen(app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 1)
        app.buttons["cancel-entry"].tap()
        discardChanges(in: app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
    }

    func testCancelKeepsWorkingOnAFormOverAnotherAfterATapOutside() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        let name = app.textFields["medication-name"]
        name.tap()
        name.typeText("Zorblex")

        askAndDismissByTapOutside(cancel: app.buttons["medication-cancel"], in: app)

        XCTAssertEqual(name.value as? String, "Zorblex")
        app.buttons["medication-cancel"].tap()
        discardChanges(in: app)
        XCTAssertTrue(name.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["dose-add-medication"].exists)
    }

    /// Two rounds of Cancel, the dialog, and a tap on the form outside the dialog, in a gap between two cards.
    private func askAndDismissByTapOutside(cancel: XCUIElement, in app: XCUIApplication) {
        let discard = app.buttons["discard-changes"].firstMatch
        let outside = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.42))
        for round in 1 ... 2 {
            XCTAssertTrue(cancel.waitForExistence(timeout: 10), "round \(round)")
            cancel.tap()
            XCTAssertTrue(discard.waitForExistence(timeout: 10), "round \(round): Cancel did not ask")
            outside.tap()
            XCTAssertTrue(discard.waitForNonExistence(timeout: 10), "round \(round): the dialog stayed")
        }
    }

    func testSwipeDownClosesWhenUnchanged() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        swipeSheetDown(app)

        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(entryRows(in: app).count, 0)
        attachScreenshot(named: "swipe-down")
    }

    func testSwipeDownIsBlockedAfterChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(1, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 1)
        XCTAssertEqual(app.alerts.count, 0)
        attachScreenshot(named: "swipe-blocked")

        app.buttons["cancel-entry"].tap()
        discardChanges(in: app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 0)
    }

    func testSwipeDownIsBlockedAfterKindChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        chooseKind(.stiffness, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
    }

    func testSwipeDownIsBlockedAfterDateChange() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 1, "Moving the hour one back wraps past midnight at 00:xx. Run after 01:00.")
        let app = launchAnky()
        openNewEntry(app)
        openDateWheel(in: app)
        moveDateHour(by: -1, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
    }

    func testSwipeDownIsBlockedAfterSeverityChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        setSeverity(7, in: app)
        swipeSheetDown(app)

        assertStillOpen(app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 7)
    }

    func testSwipeDownIsBlockedAfterNoteChange() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        typeNote("Walk note", in: app)
        dragSheetDownFromBar(app)

        assertStillOpen(app)
    }

    /// A slow drag from the top of the screen. It closes an unchanged sheet when the keyboard is down.
    private func swipeSheetDown(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    /// The keyboard is up, so a flick on the bar does not reliably reach the sheet. A slow drag from the bar does.
    /// It starts right of Cancel, so the press is not a tap on Cancel.
    private func dragSheetDownFromBar(_ app: XCUIApplication) {
        let cancel = app.buttons["cancel-entry"]
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0))
            .withOffset(CGVector(dx: 0, dy: cancel.frame.midY))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    /// The sheet is still animating for a moment after a swipe, so a plain `exists` check could pass too early.
    private func assertStillOpen(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 3), file: file, line: line)
        XCTAssertEqual(app.alerts.count, 0, file: file, line: line)
    }
}
