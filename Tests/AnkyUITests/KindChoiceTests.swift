// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import XCTest

@MainActor
final class KindChoiceTests: XCTestCase {
    func testKindIsOneSegmentedControlThatSavesEachChoice() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        XCTAssertEqual(app.segmentedControls.count, 1)
        let picker = app.segmentedControls["kind-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertEqual(picker.label, "What are you logging")
        XCTAssertEqual(picker.buttons.count, EntryKind.allCases.count)

        let minXs = EntryKind.allCases.map { kindSegment($0, in: app).frame.minX }
        XCTAssertEqual(minXs, minXs.sorted())

        XCTAssertTrue(kindSegment(.pain, in: app).isSelected)

        for kind in EntryKind.allCases {
            chooseKind(kind, in: app)
            XCTAssertTrue(kindSegment(kind, in: app).isSelected)
            for other in EntryKind.allCases where other != kind {
                XCTAssertFalse(kindSegment(other, in: app).isSelected)
            }
        }

        saveEntry(app)
        let row = app.descendants(matching: .any).matching(identifier: "entry-row-fatigue").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
    }

    func testTappingTheChosenKindKeepsSwipeDownClosing() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)
        chooseKind(.pain, in: app)
        swipeSheetDown(app)

        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 0)
    }

    /// A slow drag from the top of the screen. It closes an unchanged sheet when the keyboard is down.
    private func swipeSheetDown(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    func testStiffnessRowAndPainDefault() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        XCTAssertTrue(kindSegment(.pain, in: app).isSelected)
        attachScreenshot(named: "kind-choice-default")

        chooseKind(.stiffness, in: app)
        setSeverity(4, in: app)
        saveEntry(app)

        let row = app.descendants(matching: .any).matching(identifier: "entry-row-stiffness").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertEqual(rowSeverity(of: row), 4)
        attachScreenshot(named: "kind-choice-saved")
    }
}
