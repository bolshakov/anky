// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
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
        setDateTimeHoursBack(2, in: app)
        // The row's label reads its time in double-length text, so the time is checked on the date row before saving.
        let expected = [openedAt, Date.now].map { twoHoursEarlierTime(from: $0) }
        let shown = dateRowTime(in: app)
        XCTAssertTrue(expected.contains(shown ?? ""), "date row time is \(shown ?? "nil")")
        saveEntry(app)

        let rows = entryRows(in: app)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rowSeverity(of: rows.firstMatch), 4)
        attachScreenshot(named: "earlier-time")
    }

    private func twoHoursEarlierTime(from date: Date) -> String {
        ClockText.text(for: date.addingTimeInterval(-7200), calendar: .current, locale: Locale(identifier: "en_GB"))
    }
}
