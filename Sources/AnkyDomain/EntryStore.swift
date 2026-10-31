// SPDX-License-Identifier: GPL-3.0-or-later
public protocol EntryStore: Sendable {
    /// Returns the entries in save order, oldest saved first.
    func load() throws -> [Entry]
    func save(_ entries: [Entry]) throws
}

public enum FileProtection: Sendable {
    case complete
    case deviceDefault
}

public enum EntryStoreError: Error, Equatable {
    case unreadable
    case newerVersion(Int)
}
