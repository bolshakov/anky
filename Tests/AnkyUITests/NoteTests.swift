// SPDX-License-Identifier: GPL-3.0-or-later
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
        let typed = "Walk"
        app.typeText(typed)

        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertEqual(field.value as? String, typed)
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
        let field = app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
        XCTAssertEqual((field.value as? String)?.count, 230)
        let counter = app.descendants(matching: .any).matching(identifier: "note-counter").firstMatch
        XCTAssertTrue(counter.waitForExistence(timeout: 10))
        let counterAtTen = counter.label

        app.typeText(String(note.dropFirst(230)))

        XCTAssertEqual(field.value as? String, String(note.prefix(240)))
        XCTAssertNotEqual(counter.label, counterAtTen)
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

    func testTappingBesideTheTextFocusesField() {
        continueAfterFailure = false
        let app = launchAnky()
        openNewEntry(app)

        let card = app.descendants(matching: .any).matching(identifier: "note-card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        app.typeText("Walk")

        XCTAssertEqual(noteField(in: app).value as? String, "Walk")
    }

    func testSkinToneEmojiAsTheLastCharacterIsKept() {
        continueAfterFailure = false
        let app = launchAnky()
        let typed = String(String(repeating: "Walk note ", count: 24).prefix(239))
        let emoji = "👍🏽"

        openNewEntry(app)
        typeNote(typed, in: app)
        app.typeText(emoji)
        app.typeText("x")

        XCTAssertEqual(noteField(in: app).value as? String, typed + emoji)
        let counter = app.descendants(matching: .any).matching(identifier: "note-counter").firstMatch
        XCTAssertEqual(counter.label, "Limit reached")
    }

    func testTypingPastTheLimitInSeparateBatchesKeepsTheLimit() {
        continueAfterFailure = false
        let app = launchAnky()
        let typed = String(String(repeating: "Walk note ", count: 24).prefix(240))

        openNewEntry(app)
        typeNote(typed, in: app)
        app.typeText("x")
        app.typeText("x")
        app.typeText("x")

        XCTAssertEqual(noteField(in: app).value as? String, typed)
    }

    func testEditedNoteShowsItsTextAndCounterAndSavesUnchanged() {
        continueAfterFailure = false
        let app = launchAnky()
        let note = String(String(repeating: "Walk note ", count: 24).prefix(235))

        openNewEntry(app)
        typeNote(note, in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        entryRows(in: app).firstMatch.tap()
        XCTAssertTrue(app.scrollViews["edit-entry-screen"].waitForExistence(timeout: 10))
        XCTAssertEqual(noteField(in: app).value as? String, note)
        let counter = app.descendants(matching: .any).matching(identifier: "note-counter").firstMatch
        XCTAssertEqual(counter.label, "5 left")

        saveEntry(app)
        XCTAssertTrue(app.scrollViews["edit-entry-screen"].waitForNonExistence(timeout: 10))
        entryRows(in: app).firstMatch.tap()
        XCTAssertTrue(app.scrollViews["edit-entry-screen"].waitForExistence(timeout: 10))
        XCTAssertEqual(noteField(in: app).value as? String, note)
    }

    func testLongNoteAtLargestSizeGrowsAndKeepsSaveReachable() {
        continueAfterFailure = false
        let app = launchAnky(arguments: largestTextArguments)
        let card = app.descendants(matching: .any).matching(identifier: "note-card").firstMatch
        openNewEntry(app)
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let emptyHeight = card.frame.height

        typeNote(String(repeating: "Walk note ", count: 20), in: app)
        scrollToNoteField(in: app)

        XCTAssertGreaterThan(card.frame.height, emptyHeight)
        let save = app.buttons["save-entry"]
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(save.frame))
    }

    func testEmptyNoteFieldIsTheSystemTextField() {
        continueAfterFailure = false
        let app = launchAnky()

        openNewEntry(app)
        let asTextField = app.textFields["note-field"]
        let asTextView = app.textViews["note-field"]
        XCTAssertTrue(asTextField.waitForExistence(timeout: 10) || asTextView.exists)
        let field = asTextField.exists ? asTextField : asTextView
        XCTAssertEqual(field.label, "Note")
        XCTAssertEqual(field.placeholderValue, "Add a note")

        typeNote("Walk note", in: app)
        saveEntry(app)
        XCTAssertTrue(app.scrollViews["new-entry-screen"].waitForNonExistence(timeout: 10))

        entryRows(in: app).firstMatch.tap()
        XCTAssertTrue(app.scrollViews["edit-entry-screen"].waitForExistence(timeout: 10))
        XCTAssertEqual(noteField(in: app).value as? String, "Walk note")
    }
}

@MainActor
private func noteField(in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: "note-field").firstMatch
}
