// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInBannerTests: XCTestCase {
    /// The title shows the medication's name as typed: a percent sign, braces and a format specifier stay in it.
    func testBannerTitleReadsTheNameAsTyped() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app, medication: "Zorblex 100% {x} %@")
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        XCTAssertTrue(identified("check-in-info", in: app).label.hasPrefix("Zorblex 100% {x} %@. Taken at "))
    }

    func testBannerNamesAStiffnessBeforeReading() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.stiffness, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        let label = identified("check-in-info", in: app).label
        XCTAssertTrue(label.hasSuffix("Before: Stiffness 4."), label)
    }

    func testBannerNamesAFatigueBeforeReading() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.fatigue, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        let label = identified("check-in-info", in: app).label
        XCTAssertTrue(label.hasSuffix("Before: Fatigue 4."), label)
    }

    /// A dose with no earlier reading says only when it was taken, and names no before reading.
    func testBannerWithNoEarlierReadingSaysOnlyTheTime() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        addZorblexCheckingInAfterThirtyMinutes(app, readingRow: "log-how-you-feel-row")
        scrollToDateRow(in: app)
        setDateTimeHoursBack(1, in: app)
        app.buttons["save-dose"].tap()
        openCheckIn(app)

        let label = identified("check-in-info", in: app).label
        XCTAssertNotNil(label.range(of: #"^Zorblex\. Taken at \d{1,2}:\d\d\.$"#, options: .regularExpression), label)
    }
}
