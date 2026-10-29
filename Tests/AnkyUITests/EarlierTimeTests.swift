import XCTest

@MainActor
final class EarlierTimeTests: XCTestCase {
    func testEntryTwoHoursAgo() throws {
        continueAfterFailure = false
        let hour = Calendar.current.component(.hour, from: .now)
        try XCTSkipIf(hour < 3, "Two hours back falls on hour 00 before 03:00. Run after 03:00.")
        let app = launchAnky()
        let openedAt = Date.now
        openNewEntry(app)
        setSeverity(4, in: app)
        showDatePicker(in: app)
        moveHour(by: -2, in: app)
        app.buttons["date-row"].tap()
        // The row's label reads its time in double-length text, so the time is checked on the date row before saving.
        let expected = [openedAt, Date.now].map { twoHoursEarlierTime(from: $0) }
        let shown = clockTime(inRowValue: app.buttons["date-row"].value as? String)
        XCTAssertTrue(expected.contains(shown ?? ""), "date row time is \(shown ?? "nil")")
        saveEntry(app)

        let rows = entryRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rowSeverity(of: rows.firstMatch), 4)
        attachScreenshot(named: "earlier-time")
    }

    private func twoHoursEarlierTime(from date: Date) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "en_GB"))
        return date.addingTimeInterval(-7200).formatted(style)
    }
}
