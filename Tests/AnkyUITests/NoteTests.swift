import XCTest

@MainActor
final class NoteTests: XCTestCase {
    func testSavesWithAndWithoutNote() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        typeNote("Walk note", in: app)
        saveEntry(app)
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))

        openNewEntry(app)
        saveEntry(app)
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))

        XCTAssertTrue(todayRows(in: app).firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(todayRows(in: app).count, 2)
        attachScreenshot(named: "note-optional")
    }

    func testLongNoteKeepsSaveReachable() {
        continueAfterFailure = false
        let app = launchAnky()
        let sentences = String(repeating: "A made-up sentence that runs on for a while. ", count: 4)
        let note = (1 ... 6).map { "Paragraph \($0). \(sentences)" }.joined(separator: "\n\n")

        openNewEntry(app)
        typeNote(note, in: app)

        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertEqual(field.value as? String, note)
        let save = app.buttons["Save entry"]
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(save.frame))

        saveEntry(app)
        XCTAssertTrue(app.staticTexts["New Entry"].waitForNonExistence(timeout: 10))
    }

    private func todayRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "entry-row")
    }
}
