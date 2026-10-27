import XCTest

@MainActor
final class KindChoiceTests: XCTestCase {
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
