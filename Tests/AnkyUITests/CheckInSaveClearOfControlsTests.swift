// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// Save check-in is the last row of the form, so no control on Check In sits under it at any scroll position.
@MainActor
final class CheckInSaveClearOfControlsTests: XCTestCase {
    func testSaveCoversNoControlAtTheFirstPositionAtTheDefaultSize() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let app = launchAnky()
        setUpWaitingPainDose(in: app)
        openCheckIn(app)

        assertNoControlUnderSave(in: app)
        setSeverity(6, in: app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        XCTAssertTrue(identified("check-in-screen", in: app).exists)

        scrollToSaveCheckIn(in: app)
        assertNoControlUnderSave(in: app)
        assertNoteAndSliderAboveSave(in: app)
    }

    func testSaveCoversNoControlAtAnyScrollPositionAtTheLargestSize() throws {
        continueAfterFailure = false
        try skipUnlessAnHourBackStaysToday()
        let folder = UUID().uuidString
        let setUp = launchAnky(folder: folder)
        setUpWaitingPainDose(in: setUp)
        setUp.terminate()
        let app = launchAnky(folder: folder, arguments: largestTextArguments)
        openCheckIn(app)

        let screen = identified("check-in-screen", in: app)
        for _ in 0 ..< 6 {
            assertNoControlUnderSave(in: app)
            screen.swipeUp()
        }
        assertNoControlUnderSave(in: app)
        assertNoteAndSliderAboveSave(in: app)
        swipeBackToSlider(in: app)
        setSeverity(6, in: app)
        XCTAssertEqual(severityLevel(of: app.sliders["severity-slider"]), 6)
        XCTAssertTrue(identified("check-in-screen", in: app).exists)
    }

    /// The walk above ends at the bottom of the form, with the slider scrolled off the top, so it is swiped back.
    private func swipeBackToSlider(in app: XCUIApplication) {
        let slider = app.sliders["severity-slider"]
        let screen = identified("check-in-screen", in: app)
        for _ in 0 ..< 8 where !slider.isHittable {
            screen.swipeDown()
        }
    }

    /// Checks each control that is on screen against Save's frame. Save is found only when it is on screen, so
    /// the check is about Save wherever it sits, and a control is judged only when both are present.
    private func assertNoControlUnderSave(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let save = app.buttons["save-check-in"]
        guard save.exists else { return }
        let saveFrame = save.frame
        let controls = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'place-chip-' OR identifier IN %@", checkInControlIDs)
        )
        for index in 0 ..< controls.count {
            let control = controls.element(boundBy: index)
            guard control.exists else { continue }
            XCTAssertFalse(
                control.frame.intersects(saveFrame),
                "save-check-in at \(saveFrame) covers \(control.identifier) at \(control.frame)",
                file: file,
                line: line
            )
        }
    }

    private func assertNoteAndSliderAboveSave(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let save = app.buttons["save-check-in"]
        XCTAssertTrue(save.exists, "save-check-in is not on screen at the end of the form", file: file, line: line)
        for id in ["severity-slider", "note-field"] {
            let control = identified(id, in: app)
            XCTAssertTrue(control.exists, "\(id) is not on screen", file: file, line: line)
            XCTAssertLessThanOrEqual(control.frame.maxY, save.frame.minY, file: file, line: line)
        }
    }

    private func setUpWaitingPainDose(in app: XCUIApplication) {
        saveEntryAnHourBack(.pain, in: app)
        addZorblexCheckingInAfterThirtyMinutes(app)
        saveDoseAnHourBack(in: app)
    }
}

private let checkInControlIDs = ["kind-picker", "date-row", "more-places", "severity-slider", "note-field"]
