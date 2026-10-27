import XCTest

@MainActor
final class NoteTests: XCTestCase {
    func testSavesWithAndWithoutNote() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        typeNote("Walk note", in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        openNewEntry(app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        XCTAssertTrue(entryRows(in: app).firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(entryRows(in: app).count, 2)
        attachScreenshot(named: "note-optional")
    }

    func testEmptyNoteCardIsOneLineHigh() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let card = app.descendants(matching: .any).matching(identifier: "note-card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(card.frame.height, 44)
        XCTAssertLessThan(card.frame.height, 60, "empty note card is \(card.frame.height) pt high")
    }

    func testEmptyNoteFieldSpansTheCard() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let window = app.windows.firstMatch.frame
        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(field.frame.width, window.width * 0.8, "note field is \(field.frame.width) pt wide")
    }

    func testNoteCardGrowsWithText() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let card = app.descendants(matching: .any).matching(identifier: "note-card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let emptyHeight = card.frame.height

        typeNote("One\nTwo\nThree", in: app)

        XCTAssertGreaterThan(
            card.frame.height, emptyHeight,
            "note card stayed \(card.frame.height) pt high with three lines"
        )
    }

    func testTappingTopOfNoteCardFocusesField() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let card = app.descendants(matching: .any).matching(identifier: "note-card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        app.typeText("Walk")

        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertEqual(field.value as? String, "Walk")
    }

    func testLongNoteKeepsSaveReachable() {
        continueAfterFailure = false
        let app = launchAnky()
        let sentence = "A made-up sentence that runs on for a while. "
        let note = (1 ... 4).map { "Paragraph \($0). \(sentence)" }.joined(separator: "\n\n")

        openNewEntry(app)
        typeNote(note, in: app)

        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertEqual(field.value as? String, note)
        let save = app.buttons["save-entry"]
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(save.frame))

        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))
    }

    func testNoteStopsAtTheLimit() {
        continueAfterFailure = false
        let app = launchAnky()
        let note = String(repeating: "word ", count: 60)

        openNewEntry(app)
        typeNote(String(note.prefix(230)), in: app)
        let counter = app.descendants(matching: .any).matching(identifier: "note-counter").firstMatch
        XCTAssertTrue(counter.waitForExistence(timeout: 10))
        XCTAssertEqual(leadingNumber(in: counter.label), 10)

        app.typeText(String(note.dropFirst(230)))

        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertEqual(field.value as? String, String(note.prefix(240)))
        XCTAssertFalse(counter.label.contains { $0.isNumber })
        let save = app.buttons["save-entry"]
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(save.frame))
        for _ in 0 ..< 3 where counter.frame.maxY > save.frame.minY {
            app.swipeUp()
        }
        XCTAssertTrue(counter.isHittable)
        XCTAssertLessThanOrEqual(counter.frame.maxY, save.frame.minY)
        attachScreenshot(named: "note-limit")
    }
}
