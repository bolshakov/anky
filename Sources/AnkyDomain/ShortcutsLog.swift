// SPDX-License-Identifier: GPL-3.0-or-later
public final class ShortcutsLog {
    private let store: any ShortcutsStore
    public private(set) var shortcuts: Shortcuts

    public init(store: any ShortcutsStore) {
        self.store = store
        shortcuts = store.load()
    }

    @discardableResult
    public func pin(_ place: PlaceID) -> PinOutcome {
        update { $0.pin(place) }
    }

    @discardableResult
    public func pin(all places: [PlaceID]) -> PinOutcome {
        update { $0.pin(all: places) }
    }

    public func unpin(_ place: PlaceID) {
        update { $0.unpin(place) }
    }

    public func setLastChips(_ chips: [PlaceID]) {
        update { $0.setLastChips(chips) }
    }

    @discardableResult
    private func update<Outcome>(_ change: (inout Shortcuts) -> Outcome) -> Outcome {
        let result = change(&shortcuts)
        try? store.save(shortcuts)
        return result
    }
}
