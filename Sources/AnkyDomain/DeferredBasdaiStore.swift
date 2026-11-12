// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Opens its store on the first call, and on each later call until one open works. A store that cannot open throws
/// `unavailable` and leaves the saved results as they are, so a phone that is locked at launch can open it later.
@MainActor public final class DeferredBasdaiStore: BasdaiStore {
    private let open: @MainActor () throws -> BasdaiStore
    private var opened: BasdaiStore?

    public init(open: @escaping @MainActor () throws -> BasdaiStore) {
        self.open = open
    }

    public func all() throws -> [BasdaiResult] {
        try current().all()
    }

    public func add(_ result: BasdaiResult) throws {
        try current().add(result)
    }

    public func remove(id: UUID) throws {
        try current().remove(id: id)
    }

    public func removeAll() throws {
        try current().removeAll()
    }

    private func current() throws -> BasdaiStore {
        if let opened {
            return opened
        }
        do {
            let store = try open()
            opened = store
            return store
        } catch {
            throw BasdaiStoreError.unavailable
        }
    }
}
