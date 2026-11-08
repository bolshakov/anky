// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// At the end of the medication form's scroll, the last row sits a fixed gap above the pinned Save, with the keyboard
/// open or closed and at the largest text size. A form that fits the screen does not scroll, so it rests with its
/// last row at least that gap above Save.
@MainActor
final class MedicationSaveClearOfRowsTests: XCTestCase {
    private let gap: CGFloat = 16

    func testNewMedicationFootnoteClearsSaveByTheGapWithTheKeyboardDown() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        dismissKeyboard(in: app)

        scrollFormToEnd(in: app)
        assertClearOfSave("check-in-footnote", in: app)
    }

    func testNewMedicationFootnoteSitsSixteenPointsAboveSaveWhenTheKeyboardOpensFromName() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        assertSixteenAboveSave("check-in-footnote", in: app)
    }

    func testNewMedicationFootnoteSitsSixteenPointsAboveSaveWhenTheKeyboardOpensFromStrength() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        app.textFields["medication-strength"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        assertSixteenAboveSave("check-in-footnote", in: app)
    }

    func testCheckInMenuClearsSaveWhenCheckInLaterIsOnAndTheKeyboardIsUp() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        dismissKeyboard(in: app)
        turnOnCheckInLater(in: app)
        app.textFields["medication-strength"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        let menu = checkInMenu(in: app)
        let save = app.buttons["medication-save"]
        XCTAssertTrue(menu.exists, "dose-check-in-after is not on screen")
        XCTAssertLessThanOrEqual(
            menu.frame.maxY,
            save.frame.minY,
            "dose-check-in-after at \(menu.frame) is covered by save at \(save.frame)"
        )
        assertSixteenAboveSave("check-in-footnote", in: app)
    }

    func testFootnoteSitsSixteenPointsAboveSaveAtTheLargestTextSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        dismissKeyboard(in: app)

        scrollFormToEnd(in: app)
        assertSixteenAboveSave("check-in-footnote", in: app)
    }

    func testEditMedicationFootnoteClearsSaveByTheGapWithTheKeyboardDown() {
        continueAfterFailure = false
        let app = launchAnky()
        openEditMedication(app)
        dismissKeyboardIfShown(in: app)

        scrollFormToEnd(in: app)
        assertClearOfSave("check-in-footnote", in: app)
    }

    func testEditMedicationFootnoteClearsSaveByTheGapWhenTheKeyboardOpens() {
        continueAfterFailure = false
        let app = launchAnky()
        openEditMedication(app)
        app.textFields["medication-name"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        assertClearOfSave("check-in-footnote", in: app)
    }

    private func openEditMedication(_ app: XCUIApplication) {
        openNewMedication(app)
        saveNewMedication(named: "Zorblex", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)
    }

    private func typeIntoName(_ text: String, in app: XCUIApplication) {
        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText(text)
    }

    /// Return moves focus to Strength and a second return dismisses the keyboard, as the name helper does.
    private func dismissKeyboard(in app: XCUIApplication) {
        app.typeText("\n")
        app.typeText("\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 10))
    }

    private func dismissKeyboardIfShown(in app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else { return }
        dismissKeyboard(in: app)
    }

    private func turnOnCheckInLater(in app: XCUIApplication) {
        let toggle = checkInSwitch(in: app)
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertTrue(checkInMenu(in: app).waitForExistence(timeout: 10))
    }

    /// Drags the form up from its middle, above the bottom edge where the keyboard and Save sit, until it rests.
    private func scrollFormToEnd(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        let from = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        let to = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        for _ in 0 ..< 12 {
            from.press(forDuration: 0.1, thenDragTo: to)
        }
    }

    /// Save's top edge minus the bottom edge of the row, which must read `gap` points, within a point of rounding.
    /// Only a form that scrolls to its end can read this, so the caller names an overflowing case.
    private func assertSixteenAboveSave(
        _ id: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (row, save) = gapAboveSave(id, in: app, file: file, line: line)
        let measured = save.minY - row.maxY
        XCTAssertEqual(
            measured,
            gap,
            accuracy: 1,
            "\(id) at \(row) leaves \(measured) pt above save at \(save)",
            file: file,
            line: line
        )
    }

    /// For a form that fits the screen: the row ends at least `gap` points above Save.
    private func assertClearOfSave(
        _ id: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (row, save) = gapAboveSave(id, in: app, file: file, line: line)
        let measured = save.minY - row.maxY
        XCTAssertGreaterThanOrEqual(
            measured,
            gap,
            "\(id) at \(row) is only \(measured) pt above save at \(save)",
            file: file,
            line: line
        )
    }

    private func gapAboveSave(
        _ id: String,
        in app: XCUIApplication,
        file: StaticString,
        line: UInt
    ) -> (row: CGRect, save: CGRect) {
        let save = app.buttons["medication-save"]
        let row = identifiedInForm(id, in: app)
        XCTAssertTrue(row.exists, "\(id) is not on screen", file: file, line: line)
        XCTAssertTrue(save.exists, "medication-save is not on screen", file: file, line: line)
        return (row.frame, save.frame)
    }

    private func assertSaveAboveKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10), "the keyboard is not up", file: file, line: line)
        let save = app.buttons["medication-save"]
        XCTAssertLessThanOrEqual(
            save.frame.maxY,
            keyboard.frame.minY,
            "save at \(save.frame) is under the keyboard at \(keyboard.frame)",
            file: file,
            line: line
        )
    }

    /// Scoped to the form, since Log Dose under the sheet can print the same check-in ids.
    private func identifiedInForm(_ id: String, in app: XCUIApplication) -> XCUIElement {
        medicationForm(in: app).descendants(matching: .any).matching(identifier: id).firstMatch
    }
}
