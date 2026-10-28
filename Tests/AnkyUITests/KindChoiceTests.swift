import AnkyDomain
import XCTest

@MainActor
final class KindChoiceTests: XCTestCase {
    func testKindPillsAreButtonsWithNoSegmentedControl() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        XCTAssertEqual(app.segmentedControls.count, 0)
        let picker = app.descendants(matching: .any).matching(identifier: "kind-picker").firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertEqual(picker.buttons.count, EntryKind.allCases.count)

        XCTAssertTrue(kindSegment(.pain, in: app).isSelected)
        XCTAssertFalse(kindSegment(.stiffness, in: app).isSelected)

        chooseKind(.stiffness, in: app)
        XCTAssertTrue(kindSegment(.stiffness, in: app).isSelected)
        XCTAssertFalse(kindSegment(.pain, in: app).isSelected)
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
