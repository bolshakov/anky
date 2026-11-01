// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Opens its store on the first call, and on each later call until one open works. A store that cannot open throws
/// `unavailable` and leaves whatever it guards as it is, so a phone that is locked at launch can open it later.
@MainActor public final class DeferredEntryStore: EntryStore {
    private let open: @MainActor () throws -> any EntryStore
    private var opened: (any EntryStore)?

    public init(open: @escaping @MainActor () throws -> any EntryStore) {
        self.open = open
    }

    public func load() throws -> [Entry] {
        try current().load()
    }

    public func add(_ entry: Entry) throws {
        try current().add(entry)
    }

    public func replace(_ entry: Entry) throws {
        try current().replace(entry)
    }

    public func remove(id: UUID) throws {
        try current().remove(id: id)
    }

    private func current() throws -> any EntryStore {
        if let opened {
            return opened
        }
        do {
            let store = try open()
            opened = store
            return store
        } catch {
            throw EntryStoreError.unavailable
        }
    }
}
