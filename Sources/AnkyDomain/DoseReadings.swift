// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The entries a dose points at. An id that matches no entry reads as no reading, so a deleted entry leaves the dose
/// without it and nothing else changes.
public struct DoseReadings: Equatable, Sendable {
    public let before: Entry?
    public let after: Entry?

    public init(_ dose: Dose, in entries: [Entry]) {
        before = Self.entry(dose.beforeReadingID, in: entries)
        after = Self.entry(dose.afterReadingID, in: entries)
    }

    public init(_ dose: Dose, in entries: EntriesByID) {
        before = dose.beforeReadingID.flatMap { entries[$0] }
        after = dose.afterReadingID.flatMap { entries[$0] }
    }

    private static func entry(_ id: UUID?, in entries: [Entry]) -> Entry? {
        guard let id else { return nil }
        return entries.first { $0.id == id }
    }
}

/// The log's entries keyed by id. On a repeated id the first entry in save order wins, as `first(where:)` does.
public struct EntriesByID: Sendable {
    private let entries: [UUID: Entry]

    public init(_ entries: [Entry]) {
        self.entries = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public subscript(id: UUID) -> Entry? {
        entries[id]
    }
}
