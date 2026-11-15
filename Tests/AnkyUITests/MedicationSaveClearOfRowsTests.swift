// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// At the end of the medication form's scroll, the last row sits a fixed gap above whatever covers the form's bottom,
/// the keyboard when it is open and the bottom safe edge when it is closed, also at the largest text size. A form that
/// fits the screen does not scroll, so it rests with its last row at least that gap above it. Save is the ✓ in the top
/// bar, so it must stay on screen above the keyboard.
@MainActor
final class MedicationSaveClearOfRowsTests: XCTestCase {
    private let gap: CGFloat = 16
    /// The home indicator's height on the simulator the suite runs on, which XCUITest cannot read from the window.
    private let homeIndicatorInset: CGFloat = 34
    /// The typing suggestions bar sits above the keys and covers the form too, but XCUITest's keyboard frame starts
    /// below it.
    private let suggestionsBarHeight: CGFloat = 44

    func testNewMedicationFootnoteClearsTheBottomEdgeByTheGapWithTheKeyboardDown() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        dismissKeyboard(in: app)

        scrollFormToEnd(in: app)
        assertClearOfCover("check-in-footnote", in: app)
    }

    func testNewMedicationFootnoteSitsSixteenPointsAboveTheKeyboardAtTheLargestTextSizeWhenItOpensFromName() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        assertSixteenAboveCover("check-in-footnote", in: app)
    }

    func testNewMedicationFootnoteSitsSixteenPointsAboveTheKeyboardAtTheLargestTextSizeWhenItOpensFromStrength() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        app.textFields["medication-strength"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        assertSixteenAboveCover("check-in-footnote", in: app)
    }

    func testCheckInMenuClearsTheKeyboardAndFootnoteSitsSixteenPointsAboveItWhenCheckInLaterIsOn() {
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
        XCTAssertTrue(menu.exists, "dose-check-in-after is not on screen")
        XCTAssertLessThanOrEqual(
            menu.frame.maxY,
            coverTop(in: app),
            "dose-check-in-after at \(menu.frame) is covered from \(coverTop(in: app))"
        )
        assertSixteenAboveCover("check-in-footnote", in: app)
    }

    func testFootnoteSitsSixteenPointsAboveTheBottomEdgeAtTheLargestTextSize() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openNewMedication(app)
        typeIntoName("Zorblex", in: app)
        dismissKeyboard(in: app)

        scrollFormToEnd(in: app)
        assertSixteenAboveCover("check-in-footnote", in: app)
    }

    func testEditMedicationFootnoteClearsTheBottomEdgeByTheGapWithTheKeyboardDown() {
        continueAfterFailure = false
        let app = launchAnky()
        openEditMedication(app)
        dismissKeyboardIfShown(in: app)

        scrollFormToEnd(in: app)
        assertClearOfCover("check-in-footnote", in: app)
    }

    func testEditMedicationFootnoteClearsTheKeyboardByTheGapWhenItOpens() {
        continueAfterFailure = false
        let app = launchAnky()
        openEditMedication(app)
        app.textFields["medication-name"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))

        scrollFormToEnd(in: app)
        assertSaveAboveKeyboard(in: app)
        assertClearOfCover("check-in-footnote", in: app)
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

    /// Drags the form up along its left margin, clear of the fields, until the footnote stops moving.
    private func scrollFormToEnd(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        let from = window.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.4))
        let to = window.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.15))
        let footnote = identifiedInForm("check-in-footnote", in: app)
        var last: CGRect?
        for _ in 0 ..< 12 {
            from.press(forDuration: 0.1, thenDragTo: to)
            if footnote.exists, footnote.frame == last {
                return
            }
            last = footnote.exists ? footnote.frame : nil
        }
    }

    /// The cover's top edge minus the bottom edge of the row, which must read `gap` points, within a point of rounding.
    /// Only a form that scrolls to its end can read this, so the caller names an overflowing case.
    private func assertSixteenAboveCover(
        _ id: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (row, cover) = gapAboveCover(id, in: app, file: file, line: line)
        let measured = cover - row.maxY
        XCTAssertEqual(
            measured,
            gap,
            accuracy: 1,
            "\(id) at \(row) leaves \(measured) pt above the cover at \(cover)",
            file: file,
            line: line
        )
    }

    /// For a form that fits the screen: the row ends at least `gap` points above the cover.
    private func assertClearOfCover(
        _ id: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (row, cover) = gapAboveCover(id, in: app, file: file, line: line)
        let measured = cover - row.maxY
        XCTAssertGreaterThanOrEqual(
            measured,
            gap,
            "\(id) at \(row) is only \(measured) pt above the cover at \(cover)",
            file: file,
            line: line
        )
    }

    private func gapAboveCover(
        _ id: String,
        in app: XCUIApplication,
        file: StaticString,
        line: UInt
    ) -> (row: CGRect, cover: CGFloat) {
        let row = identifiedInForm(id, in: app)
        XCTAssertTrue(row.exists, "\(id) is not on screen", file: file, line: line)
        return (row.frame, coverTop(in: app))
    }

    /// What covers the form's bottom: the keyboard with its suggestions bar when it shows, and otherwise the bottom
    /// safe edge.
    private func coverTop(in app: XCUIApplication) -> CGFloat {
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            return keyboard.frame.minY - suggestionsBarHeight
        }
        return app.windows.firstMatch.frame.maxY - homeIndicatorInset
    }

    private func assertSaveAboveKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10), "the keyboard is not up", file: file, line: line)
        let save = app.buttons["medication-save"]
        XCTAssertTrue(save.isHittable, "medication-save is not on screen", file: file, line: line)
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
