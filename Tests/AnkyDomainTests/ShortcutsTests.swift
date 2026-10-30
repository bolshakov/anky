import AnkyDomain
import Foundation
import Testing

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
}
