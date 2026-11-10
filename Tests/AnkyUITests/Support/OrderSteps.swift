// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

@MainActor
func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
}

/// Frames come from the screen, so the test compares where each marker sits, top to bottom.
@MainActor
func assertInOrder(
    _ ids: [String],
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let tops = ids.map { id -> (id: String, top: CGFloat) in
        let found = marker(id, in: app)
        XCTAssertTrue(found.waitForExistence(timeout: 10), "\(id) is not on screen", file: file, line: line)
        return (id, found.frame.minY)
    }
    XCTAssertEqual(tops.sorted { $0.top < $1.top }.map(\.id), ids, file: file, line: line)
}

/// The date row is reached through its helper, so its name here is not an id.
@MainActor
private func marker(_ name: String, in app: XCUIApplication) -> XCUIElement {
    name == "date row" ? dateRow(in: app) : element(name, in: app)
}
