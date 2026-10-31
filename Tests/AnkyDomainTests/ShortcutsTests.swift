// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

final class FakeShortcutsStore: ShortcutsStore, @unchecked Sendable {
    private let lock = NSLock()
    private var contents: Shortcuts
    private var calls: [Shortcuts] = []
    private var failure: SaveFailure?

    init(_ contents: Shortcuts = Shortcuts()) {
        self.contents = contents
    }

    var saveCalls: [Shortcuts] {
        lock.withLock { calls }
    }

    var saved: Shortcuts {
        lock.withLock { contents }
    }

    var saveFailure: SaveFailure? {
        get { lock.withLock { failure } }
        set { lock.withLock { failure = newValue } }
    }

    func load() -> Shortcuts {
        lock.withLock { contents }
    }

    func save(_ shortcuts: Shortcuts) throws {
        try lock.withLock {
            calls.append(shortcuts)
            if let failure {
                throw failure
            }
            contents = shortcuts
        }
    }
}

struct ShortcutsTests {
    private func place(_ name: String) -> PlaceID {
        PlaceID(rawValue: name)
    }

    @Test func aSixthPinIsRefusedAndChangesNothing() {
        let names = ["a", "b", "c", "d", "e"]
        var shortcuts = Shortcuts(pinned: names.map(place))

        let outcome = shortcuts.pin(place("f"))

        #expect(outcome == .refused)
        #expect(shortcuts.pinned == names.map(place))
    }

    @Test func pinningAPinnedPlaceChangesNothing() {
        var shortcuts = Shortcuts(pinned: [place("a"), place("b")])

        let outcome = shortcuts.pin(place("a"))

        #expect(outcome == .alreadyPinned)
        #expect(shortcuts.pinned == [place("a"), place("b")])
    }

    @Test func unpinningRemovesOnlyThatPlace() {
        var shortcuts = Shortcuts(pinned: [place("a"), place("b"), place("c")])

        shortcuts.unpin(place("b"))
        shortcuts.unpin(place("z"))

        #expect(shortcuts.pinned == [place("a"), place("c")])
    }

    @Test func pinningAllIsAllOrNothing() {
        var shortcuts = Shortcuts(pinned: [place("a"), place("b"), place("c")])

        let refused = shortcuts.pin(all: [place("d"), place("e"), place("f")])
        #expect(refused == .refused)
        #expect(shortcuts.pinned == [place("a"), place("b"), place("c")])

        let pinned = shortcuts.pin(all: [place("d"), place("e")])
        #expect(pinned == .pinned)
        #expect(shortcuts.pinned == [place("a"), place("b"), place("c"), place("d"), place("e")])
    }

    @Test func pinningAllSkipsPlacesThatAreAlreadyPinned() {
        var shortcuts = Shortcuts(pinned: [place("a"), place("b")])

        let outcome = shortcuts.pin(all: [place("b"), place("c"), place("a")])

        #expect(outcome == .pinned)
        #expect(shortcuts.pinned == [place("a"), place("b"), place("c")])
    }

    @Test func pinningAllDropsPinnedPlacesBeforeCountingThem() {
        var shortcuts = Shortcuts(pinned: [place("a"), place("b"), place("c"), place("d")])

        let outcome = shortcuts.pin(all: [place("a"), place("e")])

        #expect(outcome == .pinned)
        #expect(shortcuts.pinned == [place("a"), place("b"), place("c"), place("d"), place("e")])
    }

    @Test func pinningAllOfAlreadyPinnedPlacesChangesNothing() {
        var shortcuts = Shortcuts(pinned: [place("a"), place("b")])

        let outcome = shortcuts.pin(all: [place("a"), place("b")])

        #expect(outcome == .alreadyPinned)
        #expect(shortcuts.pinned == [place("a"), place("b")])
    }

    @Test func pinningAllPinsARepeatedPlaceOnce() {
        var shortcuts = Shortcuts()

        let outcome = shortcuts.pin(all: [place("a"), place("a")])

        #expect(outcome == .pinned)
        #expect(shortcuts.pinned == [place("a")])
    }
}

struct FileShortcutsStoreTests {
    private func place(_ name: String) -> PlaceID {
        PlaceID(rawValue: name)
    }

    private let shortcuts = Shortcuts(
        pinned: [PlaceID(rawValue: "a"), PlaceID(rawValue: "b")],
        lastChips: [PlaceID(rawValue: "c"), PlaceID(rawValue: "a"), PlaceID(rawValue: "d")]
    )

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    @Test func pinsAndLastChipsReloadFromTheFile() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "shortcuts.json")
            let store = FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault)
            try store.save(shortcuts)

            let file = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any]
            #expect(file?["version"] as? Int == 1)
            #expect(file?["pinned"] as? [String] == ["a", "b"])
            #expect(file?["lastChips"] as? [String] == ["c", "a", "d"])

            try Data(#"{"version": 1, "pinned": ["a", "b"], "lastChips": ["c"]}"#.utf8).write(to: fileURL)
            let handWritten = FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault)
            #expect(handWritten.load() == Shortcuts(pinned: [place("a"), place("b")], lastChips: [place("c")]))
        }
    }

    @Test func aNewStoreOnTheSameFileSeesWhatWasSaved() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "shortcuts.json")
            try FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault).save(shortcuts)

            let reopened = FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault)
            #expect(reopened.load() == shortcuts)
        }
    }

    @Test func aMissingFileGivesNoPinsAndNoLastChips() throws {
        try withFolder { folder in
            let store = FileShortcutsStore(
                fileURL: folder.appending(path: "shortcuts.json"),
                protection: .deviceDefault
            )
            #expect(store.load() == Shortcuts())
        }
    }

    @Test func anUnreadableFileGivesNoPinsAndTheNextSaveRepairsIt() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "shortcuts.json")
            try Data("this is not a shortcuts file".utf8).write(to: fileURL)
            let store = FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault)
            #expect(store.load() == Shortcuts())

            try store.save(shortcuts)

            #expect(FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault).load() == shortcuts)
        }
    }

    @Test func aFileOfAnotherVersionGivesNoPinsAndNoLastChips() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "shortcuts.json")
            try Data(#"{"version":2,"pinned":["a"],"lastChips":["b"]}"#.utf8).write(to: fileURL)
            let store = FileShortcutsStore(fileURL: fileURL, protection: .deviceDefault)
            #expect(store.load() == Shortcuts())
        }
    }
}

struct ShortcutsLogTests {
    private func place(_ name: String) -> PlaceID {
        PlaceID(rawValue: name)
    }

    @Test func theLogStartsWithWhatTheStoreHolds() {
        let log = ShortcutsLog(store: FakeShortcutsStore(Shortcuts(pinned: [place("a")])))

        #expect(log.shortcuts.pinned == [place("a")])
    }

    @Test func eachChangeIsSavedAsItHappens() {
        let store = FakeShortcutsStore()
        let log = ShortcutsLog(store: store)

        log.pin(place("a"))
        log.setLastChips([place("b")])

        let afterPin = Shortcuts(pinned: [place("a")])
        let afterChips = Shortcuts(pinned: [place("a")], lastChips: [place("b")])
        #expect(store.saveCalls == [afterPin, afterChips])
    }

    @Test func aFailedSaveStillKeepsThePinForThisSession() {
        let store = FakeShortcutsStore()
        store.saveFailure = SaveFailure()
        let log = ShortcutsLog(store: store)

        let outcome = log.pin(place("a"))

        #expect(outcome == .pinned)
        #expect(log.shortcuts.pinned == [place("a")])
        #expect(store.saved == Shortcuts())
    }

    @Test func aRepeatedChangeAfterAFailedSaveWritesEverything() {
        let store = FakeShortcutsStore()
        let log = ShortcutsLog(store: store)
        log.pin(place("a"))
        store.saveFailure = SaveFailure()
        log.setLastChips([place("b")])
        store.saveFailure = nil

        log.setLastChips([place("b")])

        #expect(store.saved == Shortcuts(pinned: [place("a")], lastChips: [place("b")]))
    }

    @Test func theNextSaveAfterAFailureWritesEverything() {
        let store = FakeShortcutsStore()
        let log = ShortcutsLog(store: store)
        store.saveFailure = SaveFailure()
        log.pin(place("a"))
        log.setLastChips([place("b")])
        store.saveFailure = nil

        log.pin(place("c"))

        #expect(store.saved == Shortcuts(pinned: [place("a"), place("c")], lastChips: [place("b")]))
    }
}
