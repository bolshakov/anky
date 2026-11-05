// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInFootnoteTests: XCTestCase {
    private let startsAtEarlierReading =
        "Starts at your earlier reading, with the same places. Change either if it is different."

    /// The footnote names the kind Save keeps, and says the draft starts at the earlier reading when there is one.
    func testFootnoteWithAnEarlierReadingNamesTheKindSaved() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, places: ["neck", "lower"], in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)
        let pickerTop = identified("kind-picker", in: app).frame.minY

        XCTAssertEqual(footnoteText(in: app), "\(startsAtEarlierReading) Saved as a Pain entry.")
        scrollToTop(in: app, pickerTop: pickerTop)
        chooseKind(.fatigue, in: app)
        XCTAssertEqual(footnoteText(in: app), "\(startsAtEarlierReading) Saved as a Fatigue entry.")
        scrollToTop(in: app, pickerTop: pickerTop)
        chooseKind(.stiffness, in: app)
        XCTAssertEqual(footnoteText(in: app), "\(startsAtEarlierReading) Saved as a Stiffness entry.")
    }

    /// A dose with no earlier reading has no reading to start from, so the footnote names only the kind saved.
    func testFootnoteWithoutAnEarlierReadingNamesOnlyTheKindSaved() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        addZorblexCheckingInAfterThirtyMinutes(app, readingRow: "log-how-you-feel-row")
        scrollToDateRow(in: app)
        setDateTimeHoursBack(1, in: app)
        app.buttons["save-dose"].tap()
        openCheckIn(app)
        let pickerTop = identified("kind-picker", in: app).frame.minY

        XCTAssertEqual(footnoteText(in: app), "Saved as a Pain entry.")
        scrollToTop(in: app, pickerTop: pickerTop)
        chooseKind(.stiffness, in: app)
        XCTAssertEqual(footnoteText(in: app), "Saved as a Stiffness entry.")
        scrollToTop(in: app, pickerTop: pickerTop)
        chooseKind(.fatigue, in: app)
        XCTAssertEqual(footnoteText(in: app), "Saved as a Fatigue entry.")
    }

    /// The footnote sits under the severity card, between the card and the note, and the question row is gone.
    func testCheckInReadsInOrderWithTheFootnoteUnderTheSeverityCard() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, places: ["neck", "lower"], in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        XCTAssertFalse(identified("check-in-question", in: app).exists)
        assertInOrder(
            ["check-in-info", "kind-picker", "date-row", "where-section", "severity-slider", "check-in-saved-footnote"],
            in: app
        )
        scrolledToFootnote(in: app)
        scrolled(to: "note-field", in: app)
        assertInOrder(["severity-slider", "check-in-saved-footnote", "note-field"], in: app)
        scrollToSaveCheckIn(in: app)
    }

    /// Changing the kind keeps the level and the date, and the severity caption follows the kind.
    func testKindChangeKeepsTheLevelAndDateAndRenamesTheCaption() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, places: ["neck", "lower"], in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)
        let pickerTop = identified("kind-picker", in: app).frame.minY
        setSeverity(7, in: app)
        let dateBefore = identified("date-row", in: app).value as? String
        XCTAssertNotNil(dateBefore)

        scrollToTop(in: app, pickerTop: pickerTop)
        chooseKind(.fatigue, in: app)
        XCTAssertTrue(kindSegment(.fatigue, in: app).isSelected)
        scrolledToFootnote(in: app)
        let slider = app.sliders["severity-slider"]
        XCTAssertEqual(slider.label, "Fatigue now")
        XCTAssertEqual(severityLevel(of: slider), 7)
        XCTAssertEqual(identified("date-row", in: app).value as? String, dateBefore)

        scrollToTop(in: app, pickerTop: pickerTop)
        chooseKind(.stiffness, in: app)
        XCTAssertTrue(kindSegment(.stiffness, in: app).isSelected)
        scrolledToFootnote(in: app)
        XCTAssertEqual(slider.label, "Stiffness now")
        XCTAssertEqual(severityLevel(of: slider), 7)
        XCTAssertEqual(identified("date-row", in: app).value as? String, dateBefore)
    }

    private func footnoteText(in app: XCUIApplication) -> String {
        scrolledToFootnote(in: app).label
    }

    /// Scrolls the form until the footnote is on screen and can be read, then returns it.
    @discardableResult
    private func scrolledToFootnote(in app: XCUIApplication) -> XCUIElement {
        scrolled(to: "check-in-saved-footnote", in: app)
    }

    /// Swipes the form up until the element with the identifier is on screen and hittable, then returns it.
    @discardableResult
    private func scrolled(to id: String, in app: XCUIApplication) -> XCUIElement {
        let element = identified(id, in: app)
        for _ in 0 ..< 6 where !element.exists || !element.isHittable {
            identified("check-in-screen", in: app).swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        return element
    }

    /// Swipes back only while the kind picker is below its top spot, since a swipe at the top dismisses the sheet.
    private func scrollToTop(in app: XCUIApplication, pickerTop: CGFloat) {
        let screen = identified("check-in-screen", in: app)
        for _ in 0 ..< 8 where identified("kind-picker", in: app).frame.minY < pickerTop - 1 {
            screen.swipeDown()
        }
    }

    private func assertInOrder(
        _ ids: [String],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let tops = ids.map { id -> (id: String, top: CGFloat) in
            let found = identified(id, in: app)
            XCTAssertTrue(found.waitForExistence(timeout: 10), "\(id) is not on screen", file: file, line: line)
            return (id, found.frame.minY)
        }
        XCTAssertEqual(tops.sorted { $0.top < $1.top }.map(\.id), ids, file: file, line: line)
    }
}
