// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@MainActor
public protocol EntryStore {
    /// Returns the entries in save order, oldest saved first.
    func load() throws -> [Entry]
    /// A known id is a no-op.
    func add(_ entry: Entry) throws
    /// Keeps the entry's place. An unknown id throws `EntryStoreError.notSaved`.
    func replace(_ entry: Entry) throws
    /// An unknown id is a no-op.
    func remove(id: UUID) throws
}

public enum FileProtection: Sendable {
    case complete
    case deviceDefault
}

public enum EntryStoreError: Error, Equatable {
    case unreadable
    case newerVersion(Int)
    case notSaved
}
