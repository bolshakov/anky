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
        saveEntry(app)

        let rows = app.descendants(matching: .any).matching(identifier: "entry-row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        let expected = [openedAt, Date.now].map { twoHoursEarlierLabel(from: $0) }
        XCTAssertTrue(expected.contains(rows.firstMatch.label), "row reads \(rows.firstMatch.label)")
        attachScreenshot(named: "earlier-time")
    }

    private func twoHoursEarlierLabel(from date: Date) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "en_GB"))
        return "\(date.addingTimeInterval(-7200).formatted(style)), Pain, 4 of 10"
    }
}
