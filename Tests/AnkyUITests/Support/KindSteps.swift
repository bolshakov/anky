import AnkyDomain
import XCTest

@MainActor
func chooseKind(_ kind: EntryKind, in app: XCUIApplication) {
    kindSegment(kind, in: app).tap()
}

/// The segments follow `EntryKind.allCases`, so a kind is found by its place there and not by its title.
@MainActor
func kindSegment(_ kind: EntryKind, in app: XCUIApplication) -> XCUIElement {
    let picker = app.descendants(matching: .any).matching(identifier: "kind-picker").firstMatch
    XCTAssertTrue(picker.waitForExistence(timeout: 10))
    return picker.buttons.element(boundBy: EntryKind.allCases.firstIndex(of: kind)!)
}
