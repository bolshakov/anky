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
