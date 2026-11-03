// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class LogDoseReadingTests: XCTestCase {
    func testEntrySavedFromLogHowYouFeelBecomesTheBeforeReading() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        expectBeforeReadingShowsFourOfTen(app)
    }

    /// The New Entry draft starts when it opens, which can be a minute after the dose time Log Dose fixed on opening.
    /// The test above can finish inside that minute, so this one waits for the minute to roll over first.
    func testEntrySavedInALaterMinuteStillBecomesTheBeforeReading() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        let opened = clockTime(inRowValue: app.buttons["date-row"].value as? String)
        waitForMinuteToChange(from: opened)

        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)
        expectBeforeReadingShowsFourOfTen(app)
    }

    func testChooserListsTheReadingsAndOffersNoNoneChoice() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(identifier: "reading-option").count, 1)
        XCTAssertTrue(app.buttons["reading-log-new"].exists)
        let list = app.collectionViews.containing(.button, identifier: "reading-log-new")
        XCTAssertEqual(list.cells.count, 2)
    }

    func testLogHowYouFeelNowFromTheChooserSelectsTheSavedEntry() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        logThreeOfTenFromChooser(app)

        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.label.contains("3 of 10"), before.label)
    }

    func testTappingAReadingSelectsItAndMovesTheCheckMark() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)
        logThreeOfTenFromChooser(app)

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForExistence(timeout: 10))
        let options = app.buttons.matching(identifier: "reading-option")
        XCTAssertEqual(options.count, 2)
        XCTAssertTrue(readingValue(options.element(boundBy: 0)).contains("3 of 10"))
        XCTAssertTrue(options.element(boundBy: 0).isSelected)
        XCTAssertTrue(readingValue(options.element(boundBy: 1)).contains("4 of 10"))
        XCTAssertFalse(options.element(boundBy: 1).isSelected)
        options.element(boundBy: 1).tap()

        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["before-reading-row"].label.contains("4 of 10"))

        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-cancel"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons.matching(identifier: "reading-option").element(boundBy: 0).isSelected)
        XCTAssertTrue(app.buttons.matching(identifier: "reading-option").element(boundBy: 1).isSelected)
        app.buttons["reading-cancel"].tap()

        XCTAssertTrue(app.buttons["reading-cancel"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["before-reading-row"].label.contains("4 of 10"))
    }

    func testBeforeThisDoseIsASectionTitleAboveItsCardUnderMedication() throws {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        saveFourOfTenFromNewEntry(app)

        let row = app.buttons["before-reading-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let titles = elementsLabelled("Before this dose", in: app)
        XCTAssertFalse(titles.contains { row.frame.contains($0.frame) }, "the title is inside the card")
        let title = try XCTUnwrap(titles.first { $0.frame.maxY <= row.frame.minY }, "no title above the card")
        let medication = try XCTUnwrap(elementsLabelled("Medication", in: app).first)
        XCTAssertGreaterThanOrEqual(title.frame.minY, medication.frame.maxY)
    }

    func testWithoutAReadingTheSectionTitleIsLogHowYouFeelNow() {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)

        let row = app.buttons["log-how-you-feel-row"]
        let titles = elementsLabelled("Log how you feel now", in: app)
        XCTAssertTrue(titles.contains { $0.frame.maxY <= row.frame.minY }, "no title above the row")
        XCTAssertTrue(elementsLabelled("Before this dose", in: app).isEmpty)
    }

    func testReadingRowPutsThePlacesWithTheTimeAndTheLevelAtTheRight() throws {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        app.buttons["place-chip-lower"].tap()
        app.buttons["place-chip-neck"].tap()
        setSeverity(6, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))

        let row = app.buttons["before-reading-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let time = rowTime(of: row)
        let places = try XCTUnwrap(textInRow("Neck and Lower back · \(time)", in: row, app))
        let level = try XCTUnwrap(textInRow("6 of 10", in: row, app))
        XCTAssertNotNil(textInRow("Pain", in: row, app))
        XCTAssertGreaterThan(level.frame.minX, places.frame.maxX)
        XCTAssertGreaterThan(level.frame.midX, row.frame.midX)
        XCTAssertEqual(row.label, "\(time), Pain, Neck and Lower back, 6 of 10")
    }

    func testAFatigueReadingShowsOnlyItsTimeUnderTheKind() throws {
        continueAfterFailure = false
        let app = launchAnky()
        addZorblex(app)
        openHowYouFeel(app)
        chooseKind(.fatigue, in: app)
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))

        let row = app.buttons["before-reading-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let time = try XCTUnwrap(textInRow(rowTime(of: row), in: row, app))
        let kind = try XCTUnwrap(textInRow("Fatigue", in: row, app))
        let level = try XCTUnwrap(textInRow("4 of 10", in: row, app))
        XCTAssertGreaterThan(time.frame.minY, kind.frame.minY)
        XCTAssertLessThan(time.frame.minX, level.frame.minX)
        let texts = app.staticTexts.allElementsBoundByIndex.filter { row.frame.contains($0.frame) }
        XCTAssertFalse(texts.contains { $0.label.contains("·") })
    }

    /// Section titles have no id, so they are found by their text.
    private func elementsLabelled(_ text: String, in app: XCUIApplication) -> [XCUIElement] {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", text)).allElementsBoundByIndex
    }

    /// Only the texts inside the row's frame count, since a list under the sheet can show the same words.
    private func textInRow(_ text: String, in row: XCUIElement, _ app: XCUIApplication) -> XCUIElement? {
        app.staticTexts.allElementsBoundByIndex.first { $0.label == text && row.frame.contains($0.frame) }
    }

    private func logThreeOfTenFromChooser(_ app: XCUIApplication) {
        app.buttons["before-reading-row"].tap()
        XCTAssertTrue(app.buttons["reading-log-new"].waitForExistence(timeout: 10))
        app.buttons["reading-log-new"].tap()
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForExistence(timeout: 10))
        setSeverity(3, in: app)
        saveEntry(app)
    }

    private func readingValue(_ option: XCUIElement) -> String {
        option.value as? String ?? ""
    }

    /// Leaves Log Dose showing its "Log how you feel" row.
    private func addZorblex(_ app: XCUIApplication) {
        app.buttons["log-medication"].tap()
        app.buttons["dose-add-medication"].tap()
        let name = app.textFields["medication-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Zorblex")
        app.buttons["medication-save"].tap()
        XCTAssertTrue(app.buttons["log-how-you-feel-row"].waitForExistence(timeout: 10))
    }

    private func openHowYouFeel(_ app: XCUIApplication) {
        app.buttons["log-how-you-feel-row"].tap()
        XCTAssertTrue(entryScreen(app).waitForExistence(timeout: 10))
    }

    private func saveFourOfTenFromNewEntry(_ app: XCUIApplication) {
        setSeverity(4, in: app)
        saveEntry(app)
        XCTAssertTrue(entryScreen(app).waitForNonExistence(timeout: 10))
    }

    private func expectBeforeReadingShowsFourOfTen(_ app: XCUIApplication) {
        let before = app.buttons["before-reading-row"]
        XCTAssertTrue(before.waitForExistence(timeout: 10))
        XCTAssertTrue(before.label.contains("Pain"), before.label)
        XCTAssertTrue(before.label.contains("4 of 10"), before.label)
        XCTAssertFalse(app.buttons["log-how-you-feel-row"].exists)
    }

    private func waitForMinuteToChange(from minute: String?) {
        let deadline = Date.now.addingTimeInterval(90)
        while clockTime(at: .now) == minute, Date.now < deadline {
            Thread.sleep(forTimeInterval: 1)
        }
        XCTAssertNotEqual(clockTime(at: .now), minute)
    }
}
