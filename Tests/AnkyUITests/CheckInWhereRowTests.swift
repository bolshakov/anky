// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import XCTest

@MainActor
final class CheckInWhereRowTests: XCTestCase {
    func testCheckInAfterAFatigueReadingHasNoWhereRow() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.fatigue, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        let question = identified("check-in-question", in: app)
        XCTAssertTrue(question.label.lowercased().contains("fatigue"), question.label)
        scrollToBottom(of: app)
        XCTAssertTrue(identified("date-row", in: app).exists)
        XCTAssertFalse(identified("where-row", in: app).exists)
    }

    func testCheckInAfterAPainReadingHasAWhereRow() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
        openCheckIn(app)

        let question = identified("check-in-question", in: app)
        XCTAssertTrue(question.label.lowercased().contains("pain"), question.label)
        scrollToBottom(of: app)
        XCTAssertTrue(identified("where-row", in: app).waitForExistence(timeout: 10))
    }
}
