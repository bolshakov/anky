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

    private static func entry(_ id: UUID?, in entries: [Entry]) -> Entry? {
        guard let id else { return nil }
        return entries.first { $0.id == id }
    }
}
