// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class TakenAsChoiceTests: XCTestCase {
    func testDefaultSizeShowsOneSegmentedControlWithAsNeededSelected() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)

        XCTAssertTrue(app.segmentedControls["taken-as"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.segmentedControls.count, 1)
        XCTAssertEqual(segmentLabels(in: app), ["As needed", "Scheduled"])
        XCTAssertEqual(selectedChoice(in: app), "As needed")
    }

    func testChoiceIsSavedAndShownOnEditMedication() {
        continueAfterFailure = false
        let app = launchAnky()
        addFirstMedication(app, scheduled: true)
        openMedicationsFromLogDose(app)

        openMedicationFromList(app)
        XCTAssertEqual(selectedChoice(in: app), "Scheduled")
        choose("As needed", in: app)
        saveChanges(app)

        openMedicationFromList(app)
        XCTAssertEqual(selectedChoice(in: app), "As needed")
    }

    func testCancelKeepsTheSavedChoice() {
        continueAfterFailure = false
        let app = launchAnky()
        addFirstMedication(app, scheduled: true)
        openMedicationsFromLogDose(app)

        openMedicationFromList(app)
        choose("As needed", in: app)
        app.buttons["medication-cancel"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))

        openMedicationFromList(app)
        XCTAssertEqual(selectedChoice(in: app), "Scheduled")
    }

    func testLargestSizeShowsAMenuWithBothOptionsAndSavesTheChoice() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        openLogDose(app)
        app.buttons["dose-add-medication"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["taken-as"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.segmentedControls["taken-as"].exists)

        scrollToChoice(in: app)
        XCTAssertEqual(selectedChoice(in: app), "As needed")
        for dx in [0.1, 0.9] {
            openChoiceMenu(in: app, atWidth: dx)
            XCTAssertTrue(app.buttons["Scheduled"].waitForExistence(timeout: 10), "no menu from dx \(dx)")
            app.buttons["As needed"].tap()
            XCTAssertTrue(app.buttons["Scheduled"].waitForNonExistence(timeout: 10))
        }
        let asNeededBeforeOpening = asNeededCount(in: app)
        openChoiceMenu(in: app)
        XCTAssertTrue(app.buttons["Scheduled"].waitForExistence(timeout: 10))
        XCTAssertGreaterThan(asNeededCount(in: app), asNeededBeforeOpening)
        app.buttons["Scheduled"].tap()
        saveNewMedication(named: "Zorblex", app)

        openMedicationsFromLogDose(app)
        XCTAssertTrue(app.buttons["medication-row"].firstMatch.label.contains("Scheduled"))
    }

    func testScheduledMedicationOpensAtLargestSizeShowingScheduled() {
        continueAfterFailure = false
        let folder = UUID().uuidString
        let app = launchAnky(folder: folder)
        addFirstMedication(app, scheduled: true)
        app.terminate()

        let relaunched = launchAnky(folder: folder, arguments: largestTextArguments)
        openLogDose(relaunched)
        openMedicationsFromLogDose(relaunched)
        openMedicationFromList(relaunched)
        XCTAssertEqual(selectedChoice(in: relaunched), "Scheduled")
    }

    func testLargestNonAccessibilitySizeShowsBothOptionsInOneSegmentedRow() {
        continueAfterFailure = false
        let arguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        let app = launchAnky(arguments: arguments)
        openNewMedication(app)

        XCTAssertTrue(app.segmentedControls["taken-as"].waitForExistence(timeout: 10))
        let segments = app.segmentedControls["taken-as"].buttons.allElementsBoundByIndex
        XCTAssertEqual(segments.map(\.label), ["As needed", "Scheduled"])
        XCTAssertEqual(Set(segments.map(\.frame.minY)).count, 1)
        attachScreenshot(named: "taken-as-xxxl")
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

    /// Only a medication gives Log Dose its Manage button, so the first one is added from Log Dose.
    private func addFirstMedication(_ app: XCUIApplication, scheduled: Bool) {
        openNewMedication(app)
        if scheduled {
            choose("Scheduled", in: app)
        }
        saveNewMedication(named: "Zorblex", app)
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
        scrollBackToTop(until: field, in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(name)
        app.buttons["medication-save"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 10))
    }

    private func saveChanges(_ app: XCUIApplication) {
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForNonExistence(timeout: 10))
    }

    private func choose(_ option: String, in app: XCUIApplication) {
        scrollToChoice(in: app)
        let segmented = app.segmentedControls["taken-as"]
        if segmented.exists {
            segmented.buttons[option].tap()
        } else {
            openChoiceMenu(in: app)
            app.buttons[option].tap()
        }
    }

    /// Counted before and after opening, so an "As needed" label that is on screen while the menu is shut does not
    /// count.
    private func asNeededCount(in app: XCUIApplication) -> Int {
        app.buttons.matching(NSPredicate(format: "label == 'As needed'")).count
    }

    /// A row scrolled off is missing from the lazy list, and one under the navigation bar takes no focus.
    /// The drag runs down the page margin, since one that starts on the menu row does not always scroll.
    private func scrollBackToTop(until element: XCUIElement, in app: XCUIApplication) {
        let navigationBarBottom = app.navigationBars.firstMatch.frame.maxY
        let window = app.windows.firstMatch
        let from = window.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.2))
        let to = window.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5))
        for _ in 0 ..< 5 where !element.exists || element.frame.minY < navigationBarBottom {
            from.press(forDuration: 0.1, thenDragTo: to)
        }
    }

    private func openChoiceMenu(in app: XCUIApplication, atWidth dx: Double = 0.5) {
        app.buttons["taken-as"].coordinate(withNormalizedOffset: CGVector(dx: dx, dy: 0.5)).tap()
    }

    private func segmentLabels(in app: XCUIApplication) -> [String] {
        app.segmentedControls["taken-as"].buttons.allElementsBoundByIndex.map(\.label)
    }

    private func selectedChoice(in app: XCUIApplication) -> String? {
        let segmented = app.segmentedControls["taken-as"]
        if segmented.exists {
            return segmented.buttons.allElementsBoundByIndex.first(where: \.isSelected)?.label
        }
        return app.buttons["taken-as"].value as? String
    }

    /// The pinned Save button covers the bottom of the form, so the choice must scroll above it,
    /// not merely be on screen.
    private func scrollToChoice(in app: XCUIApplication) {
        let choice = app.descendants(matching: .any).matching(identifier: "taken-as").firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        let save = app.buttons["medication-save"]
        for _ in 0 ..< 5 where choice.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        XCTAssertLessThanOrEqual(choice.frame.maxY, save.frame.minY)
    }
}
