// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
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

    func testFootnoteAsksToTurnItOnWhileOffAndReadsOneSentenceWhenOn() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        addMedication(named: "Zorblex", app)
        XCTAssertEqual(
            footnote(app).label,
            "Anky asks how you feel after this long. Turn it on to choose a time."
        )

        toggleCheckIn(app)
        XCTAssertEqual(footnote(app).label, "Anky asks how you feel after this long.")
        let saved = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Saved for'"))
        XCTAssertEqual(saved.count, 0)
    }

    func testFootnoteNamesTheKindOfAPainReadingInBothStates() {
        expectFootnotes(of: .pain, "Anky asks how your pain is after this long.")
    }

    func testFootnoteNamesTheKindOfAStiffnessReadingInBothStates() {
        expectFootnotes(of: .stiffness, "Anky asks how stiff you are after this long.")
    }

    func testFootnoteNamesTheKindOfAFatigueReadingInBothStates() {
        expectFootnotes(of: .fatigue, "Anky asks how tired you are after this long.")
    }

    func testFootnoteFollowsTheReadingPickedOnChooseAReading() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        addMedication(named: "Zorblex", app)
        logReading(.stiffness, level: 4, app)
        app.buttons["before-reading-row"].tap()
        app.buttons["reading-log-new"].tap()
        XCTAssertTrue(entryScreen(app).waitForExistence(timeout: 10))
        chooseKind(.fatigue, in: app)
        setSeverity(3, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
        XCTAssertEqual(
            footnote(app).label,
            "Anky asks how tired you are after this long. Turn it on to choose a time."
        )

        app.buttons["before-reading-row"].tap()
        let options = app.buttons.matching(identifier: "reading-option")
        XCTAssertTrue(options.element(boundBy: 1).waitForExistence(timeout: 10))
        options.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(
            footnote(app).label,
            "Anky asks how stiff you are after this long. Turn it on to choose a time."
        )
    }

    func testSavingTheDoseWritesTheSwitchAndMenuBackToTheMedication() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        addMedication(named: "Quibbanol", delay: "1 hour", app)

        toggleCheckIn(app)
        saveDose(app)
        app.buttons["log-medication"].tap()
        expectCheckIn(on: false, delay: nil, app)

        toggleCheckIn(app)
        app.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch.tap()
        let item = app.buttons["4 hours"]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item 4 hours")
        item.tap()
        saveDose(app)
        app.buttons["log-medication"].tap()
        expectCheckIn(on: true, delay: "4 hours", app)
    }

    func testManageEditFollowsOnLogDoseUntilThePersonChangesTheCheckIn() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        addMedication(named: "Zorblex", delay: "2 hours", app)

        editDelayInManage("4 hours", app)
        expectCheckIn(on: true, delay: "4 hours", app)

        pickDelayOnLogDose("1 hour", app)
        expectCheckIn(on: true, delay: "1 hour", app)
        editDelayInManage("30 minutes", app)
        expectCheckIn(on: true, delay: "1 hour", app)
    }

    func testFormDelayMenuOpensFromTheTopAndBottomOfItsRow() {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()
        let form = app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
        let toggle = form.descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        let menu = form.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where menu.frame.maxY > save.frame.minY {
            app.swipeUp()
        }

        for dy in [0.1, 0.9] {
            menu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            XCTAssertTrue(app.buttons["4 hours"].waitForExistence(timeout: 10), "no menu from dy \(dy)")
            app.buttons["1 hour"].tap()
            XCTAssertTrue(app.buttons["4 hours"].waitForNonExistence(timeout: 10))
        }
    }

    /// Opens the medication from Manage, picks the delay in its form, and goes back to Log Dose.
    private func editDelayInManage(_ delay: String, _ app: XCUIApplication) {
        app.buttons["log-dose-manage"].tap()
        let row = app.buttons["medication-row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        let form = app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
        let menu = form.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where menu.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        menu.tap()
        let item = app.buttons[delay]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(delay)")
        item.tap()
        save.tap()
        let back = app.navigationBars.buttons["Log Dose"]
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
        XCTAssertTrue(app.buttons["save-dose"].waitForExistence(timeout: 10))
    }

    private func pickDelayOnLogDose(_ delay: String, _ app: XCUIApplication) {
        let menu = app.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.tap()
        let item = app.buttons[delay]
        XCTAssertTrue(item.waitForExistence(timeout: 10), "no menu item \(delay)")
        item.tap()
    }

    /// With the switch off the footnote is the sentence and the ask to turn it on, and with it on only the sentence.
    private func expectFootnotes(of kind: EntryKind, _ sentence: String) {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        addMedication(named: "Zorblex", app)
        logReading(kind, level: 4, app)
        XCTAssertEqual(footnote(app).label, "\(sentence) Turn it on to choose a time.")

        toggleCheckIn(app)
        XCTAssertEqual(footnote(app).label, sentence)
    }

    private func logReading(_ kind: EntryKind, level: Int, _ app: XCUIApplication) {
        app.buttons["log-how-you-feel-row"].tap()
        XCTAssertTrue(entryScreen(app).waitForExistence(timeout: 10))
        chooseKind(kind, in: app)
        setSeverity(level, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
    }

    private func checkInToggle(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
    }

    private func footnote(_ app: XCUIApplication) -> XCUIElement {
        let text = app.descendants(matching: .any).matching(identifier: "check-in-footnote").firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 10))
        return text
    }

    /// A tap at the centre of the row misses the switch, so this taps where the switch sits.
    private func toggleCheckIn(_ app: XCUIApplication) {
        checkInToggle(app).coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
    }

    private func saveDose(_ app: XCUIApplication) {
        app.buttons["save-dose"].tap()
        XCTAssertTrue(app.buttons["log-medication"].waitForExistence(timeout: 10))
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
        let form = app.descendants(matching: .any).matching(identifier: "medication-form").firstMatch
        let toggle = form.descendants(matching: .any).matching(identifier: "check-in-later").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where toggle.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        let menu = form.descendants(matching: .any).matching(identifier: "dose-check-in-after").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        let name = form.descendants(matching: .any).matching(identifier: "medication-name").firstMatch
        for _ in 0 ..< 5 where menu.frame.maxY > save.frame.minY {
            toggle.press(forDuration: 0.1, thenDragTo: name)
        }
        menu.tap()
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
