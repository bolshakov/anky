// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@MainActor public protocol BasdaiStore: AnyObject {
    func all() throws -> [BasdaiResult]
    func add(_ result: BasdaiResult) throws
    /// Throws `notSaved` for an id the store does not hold.
    func remove(id: UUID) throws
    /// Deletes every result in one commit. On failure, deletes none. On an empty store, does nothing.
    func removeAll() throws
}

/// Carries no field, so an error text or log line cannot show an answer, a score or a date.
public enum BasdaiStoreError: Error, Equatable {
    case unreadable
    case notSaved
    case unavailable
}
