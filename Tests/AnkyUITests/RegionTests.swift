import Foundation
import XCTest

@MainActor
final class RegionTests: XCTestCase {
    func testDatesFollowRussia() {
        checkDatesFollowRegion(language: "ru", region: "RU")
    }

    func testDatesFollowGermany() {
        checkDatesFollowRegion(language: "de", region: "DE")
    }

    /// The app shows `Date.now`, so each shown text may hold the moment before or after the read, as the entry
    /// row's time may fall in the minute before or after the save.
    private func checkDatesFollowRegion(language: String, region: String) {
        continueAfterFailure = false
        // No Russian or German words ship yet, so the app shows English words in the region's formats.
        let locale = Locale(identifier: "en_\(region)")
        let app = launchAnky(presentation: .region(language: language, region: region))

        let dayBefore = dayText(at: .now, in: locale)
        let todayDate = app.staticTexts["today-date"]
        XCTAssertTrue(todayDate.waitForExistence(timeout: 10))
        XCTAssertTrue(
            [dayBefore, dayText(at: .now, in: locale)].contains(todayDate.label),
            "today-date is \(todayDate.label)"
        )

        let clockBefore = clockText(at: .now, in: locale)
        openNewEntry(app)
        let row = app.buttons["date-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(
            [clockBefore, clockText(at: .now, in: locale)].contains(clockTime(inRowValue: row.value as? String)),
            "date-row is \(row.value as? String ?? "nil")"
        )

        let rowTimeBefore = listTimeText(at: .now, in: locale)
        setSeverity(4, in: app)
        saveEntry(app)
        let entry = entryRows(in: app).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        XCTAssertTrue([rowTimeBefore, listTimeText(at: .now, in: locale)].contains(rowTime(of: entry)),
                      "entry row time is \(rowTime(of: entry))")
    }

    private func dayText(at date: Date, in locale: Locale) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
    }

    private func clockText(at date: Date, in locale: Locale) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits).locale(locale))
    }

    private func listTimeText(at date: Date, in locale: Locale) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }
}
