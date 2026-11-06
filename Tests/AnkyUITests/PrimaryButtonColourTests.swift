// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// The label must read the way the simulator's look draws it, so a run in either look checks its own label.
@MainActor
final class PrimaryButtonColourTests: XCTestCase {
    func testTodayLogButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        let button = app.buttons["log-entry"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "today-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testNewEntrySaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        let button = app.buttons["save-entry"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "new-entry-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testEditEntrySaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app, id: "new-entry-screen").waitForNonExistence(timeout: 10))
        entryRows(in: app).firstMatch.tap()
        XCTAssertTrue(entryScreen(app, id: "edit-entry-screen").waitForExistence(timeout: 10))
        let button = app.buttons["save-entry"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "edit-entry-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testLogDoseSaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let button = app.buttons["save-dose"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "log-dose-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testEditDoseSaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        app.buttons["save-dose"].tap()
        XCTAssertTrue(doseRow(in: app).waitForExistence(timeout: 10))
        doseRow(in: app).tap()
        XCTAssertTrue(editDoseScreen(in: app).waitForExistence(timeout: 10))
        let button = app.buttons["save-dose-changes"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "edit-dose-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testMedicationsAddButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        app.buttons["log-dose-manage"].tap()
        let button = app.buttons["medications-add"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "medications-add-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testDonePlacesButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        app.buttons["more-places"].tap()
        let button = app.buttons["done-places"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "done-places-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testCheckInSaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        identified("dose-row", in: app).tap()
        scrollToSaveCheckIn(in: app)
        let button = app.buttons["save-check-in"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "check-in-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testMedicationFormSaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        app.textFields["medication-name"].tap()
        app.textFields["medication-name"].typeText("Quuxal")
        let button = app.buttons["medication-save"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "medication-form-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testEditMedicationSaveButtonLabelMatchesAppearance() throws {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        saveNewMedication(named: "Quuxal", app)
        openMedicationsFromLogDose(app)
        openMedicationFromList(app)
        let button = app.buttons["medication-save"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))

        let dark = runIsDark
        let colour = try settledLabelColour(of: button, dark: dark)
        attachScreenshot(named: "edit-medication-label")
        expectPrimaryLabel(colour, dark: dark)
    }

    func testSaveMedicationLabelIsDimmerWhenDisabled() throws {
        continueAfterFailure = false
        let app = launchAnky()
        openNewMedication(app)
        let button = app.buttons["medication-save"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        XCTAssertFalse(button.isEnabled)
        let disabled = try labelColour(of: button, threshold: dimmedLabelThreshold)
        attachScreenshot(named: "save-medication-disabled")

        app.textFields["medication-name"].tap()
        app.textFields["medication-name"].typeText("Quuxal")
        XCTAssertTrue(waitUntilEnabled(button))
        let enabled = try settledLabelColour(of: button, dark: runIsDark)
        attachScreenshot(named: "save-medication-enabled")
        XCTAssertLessThan(
            disabled.contrast, enabled.contrast / 2,
            "disabled label \(disabled.label) on \(disabled.background) is not dimmer than "
                + "enabled \(enabled.label) on \(enabled.background)"
        )
    }

    func testTodayLogButtonFollowsAppearanceChangeWithoutRelaunch() throws {
        continueAfterFailure = false
        let original = XCUIDevice.shared.appearance
        addTeardownBlock {
            MainActor.assumeIsolated { XCUIDevice.shared.appearance = original }
        }
        XCUIDevice.shared.appearance = .light
        let app = launchAnky()
        let button = app.buttons["log-entry"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        try expectPrimaryLabel(settledLabelColour(of: button, dark: false), dark: false)

        XCUIDevice.shared.appearance = .dark
        try expectPrimaryLabel(settledLabelColour(of: button, dark: true), dark: true)

        XCUIDevice.shared.appearance = .light
        try expectPrimaryLabel(settledLabelColour(of: button, dark: false), dark: false)
    }

    func testSaveDoseLabelIsDimmerWhenDisabled() throws {
        continueAfterFailure = false
        let app = launchAnky()
        app.buttons["log-medication"].tap()
        let button = app.buttons["save-dose"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        XCTAssertFalse(button.isEnabled)
        let disabled = try labelColour(of: button, threshold: dimmedLabelThreshold)
        attachScreenshot(named: "save-dose-disabled")

        addMedication("Zorblex", in: app)
        XCTAssertTrue(waitUntilEnabled(button))
        let enabled = try settledLabelColour(of: button, dark: runIsDark)
        attachScreenshot(named: "save-dose-enabled")
        XCTAssertLessThan(
            disabled.contrast, enabled.contrast / 2,
            "disabled label \(disabled.label) on \(disabled.background) is not dimmer than "
                + "enabled \(enabled.label) on \(enabled.background)"
        )
    }

    /// A disabled label sits close to its fill, so the test samples at a threshold that finds it.
    private let dimmedLabelThreshold = 20

    private func waitUntilEnabled(_ element: XCUIElement) -> Bool {
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: element)
        return XCTWaiter().wait(for: [enabled], timeout: 10) == .completed
    }

    private var runIsDark: Bool {
        XCUIDevice.shared.appearance == .dark
    }

    /// The accent fill is the one the look draws behind a primary button, within a tolerance for anti-aliasing.
    private func expectPrimaryLabel(
        _ colour: LabelColour,
        dark: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let label = colour.label
        if dark {
            XCTAssertLessThanOrEqual(max(label.red, label.green, label.blue), 90,
                                     "label reads \(label) on \(colour.background), not dark", file: file, line: line)
        } else {
            XCTAssertFalse(colour.isDark, "label reads \(label) on \(colour.background), dark in light mode",
                           file: file, line: line)
        }
        let fill = dark ? (red: 255.0, green: 118.0, blue: 75.0) : (red: 193.0, green: 59.0, blue: 20.0)
        XCTAssertEqual(colour.background.red, fill.red, accuracy: 12, file: file, line: line)
        XCTAssertEqual(colour.background.green, fill.green, accuracy: 12, file: file, line: line)
        XCTAssertEqual(colour.background.blue, fill.blue, accuracy: 12, file: file, line: line)
    }
}
