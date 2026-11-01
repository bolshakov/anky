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

        choose("Scheduled", in: app)
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
        app.buttons["log-medication"].tap()
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
            app.buttons["taken-as"].tap()
            app.buttons[option].tap()
        }
    }

    private func segmentLabels(in app: XCUIApplication) -> [String] {
        app.segmentedControls["taken-as"].buttons.allElementsBoundByIndex.map(\.label)
    }

    private func selectedChoice(in app: XCUIApplication) -> String? {
        let segmented = app.segmentedControls["taken-as"]
        if segmented.exists {
            return segmented.buttons.allElementsBoundByIndex.first(where: \.isSelected)?.label
        }
        let prefix = "How you take it, "
        let label = app.buttons["taken-as"].label
        guard label.hasPrefix(prefix) else { return nil }
        return String(label.dropFirst(prefix.count))
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
