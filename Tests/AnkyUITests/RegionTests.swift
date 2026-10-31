// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import XCTest

@MainActor
final class RegionTests: XCTestCase {
    func testDatesFollowRussia() {
        checkDatesFollowRegion(language: "ru", region: "RU", locale: Locale(identifier: "ru_RU"))
    }

    func testDatesFollowGermany() {
        // No German words ship yet.
        checkDatesFollowRegion(language: "de", region: "DE", locale: Locale(identifier: "en_DE"))
    }

    /// The app shows `Date.now`, so each shown text may hold the moment before or after the read, as the entry
    /// row's time may fall in the minute before or after the save.
    private func checkDatesFollowRegion(language: String, region: String, locale: Locale) {
        continueAfterFailure = false
        let app = launchAnky(presentation: .region(language: language, region: region))

        let dayBefore = dayText(at: .now, in: locale)
        let todayDate = app.staticTexts["today-date"]
        XCTAssertTrue(todayDate.waitForExistence(timeout: 10))
        let shownDay = todayDate.label
        XCTAssertTrue(
            [dayBefore, dayText(at: .now, in: locale)].contains(shownDay),
            "today-date is \(shownDay)"
        )

        let clockBefore = clockText(at: .now, in: locale)
        // The saved time is the moment New Entry opens, so the row time is read before it opens.
        let rowTimeBefore = listTimeText(at: .now, in: locale)
        openNewEntry(app)
        let row = app.buttons["date-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let shownRow = row.value as? String
        XCTAssertTrue(
            [clockBefore, clockText(at: .now, in: locale)].contains(clockTime(inRowValue: shownRow)),
            "date-row is \(shownRow ?? "nil")"
        )

        setSeverity(4, in: app)
        saveEntry(app)
        let entry = entryRows(in: app).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        XCTAssertTrue([rowTimeBefore, listTimeText(at: .now, in: locale)].contains(rowTime(of: entry)),
                      "entry row time is \(rowTime(of: entry))")
    }

    /// The shown date starts with a capital letter, where `Date.formatted` leaves a Russian weekday in lower case.
    private func dayText(at date: Date, in locale: Locale) -> String {
        let text = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func clockText(at date: Date, in locale: Locale) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits).locale(locale))
    }

    private func listTimeText(at date: Date, in locale: Locale) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    }
}
