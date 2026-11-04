// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
final class CheckInAccessibilityTests: XCTestCase {
    /// A Pain reading at 4 of 10 is the dose's before-reading, so Check In starts at it.
    func testWaitingDoseSpeaksItsWords() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)

        let todayRow = identified("check-in-row", in: app)
        XCTAssertTrue(todayRow.waitForExistence(timeout: 10))
        XCTAssertTrue(todayRow.label.hasPrefix("How is your pain now? After your Zorblex at "), todayRow.label)

        app.tabBars.buttons["History"].tap()
        let historyRow = identified("dose-row", in: app)
        XCTAssertTrue(historyRow.waitForExistence(timeout: 10))
        XCTAssertTrue(historyRow.label.hasSuffix("Pain was 4 of 10. Check in pending."), historyRow.label)
        historyRow.tap()

        XCTAssertTrue(identified("check-in-screen", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(identified("check-in-info", in: app).label.hasSuffix("Pain was 4 of 10 then."))
        XCTAssertTrue(kindSegment(.pain, in: app).isSelected)
        let slider = app.sliders["severity-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        XCTAssertEqual(slider.label, "Pain now")
        XCTAssertEqual(severityLevel(of: slider), 4)
        scrollToBottom(of: app)
        XCTAssertEqual(identified("more-places", in: app).value as? String, "None")
    }

    func testDefaultSizeScreensPassTheAudit() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        try auditTheWaitingDoseScreens(in: launchAnky())
    }

    func testLargestSizeScreensPassTheAudit() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        try auditTheWaitingDoseScreens(in: launchAnky(arguments: largestTextArguments))
    }

    /// Log Dose, then Today, History and Check In with the bottom of the form in view.
    private func auditTheWaitingDoseScreens(in app: XCUIApplication) throws {
        tapLogMedication(in: app)
        XCTAssertTrue(app.buttons["log-dose-cancel"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
        app.buttons["log-dose-cancel"].tap()

        setUpWaitingPainDose(in: app)
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])

        app.tabBars.buttons["History"].tap()
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])

        identified("dose-row", in: app).tap()
        XCTAssertTrue(identified("check-in-screen", in: app).waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
        scrollToBottom(of: app)
        try app.performAccessibilityAudit(for: [.hitRegion, .textClipped])
    }

    /// A Pain reading at 4 of 10 an hour back, and a Zorblex dose an hour back that takes it, so Today holds a waiting
    /// dose.
    private func setUpWaitingPainDose(in app: XCUIApplication) {
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
    }
}
