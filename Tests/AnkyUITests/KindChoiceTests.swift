import XCTest

@MainActor
final class KindChoiceTests: XCTestCase {
    func testStiffnessRowAndPainDefault() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let picker = app.segmentedControls["kind-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertTrue(picker.buttons["Pain"].isSelected)
        attachScreenshot(named: "kind-choice-default")

        chooseKind("Stiffness", in: app)
        setSeverity(4, in: app)
        saveEntry(app)

        let row = app.descendants(matching: .any).matching(identifier: "entry-row").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.label.hasSuffix(", Stiffness, 4 of 10"), "row reads \(row.label)")
        attachScreenshot(named: "kind-choice-saved")
    }
}
