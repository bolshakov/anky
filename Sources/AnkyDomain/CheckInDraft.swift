// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public extension DoseReadings {
    /// The kind a Check In asks about: the before-reading's, or Pain when the dose has none.
    var checkInKind: EntryKind {
        before?.kind ?? .pain
    }

    /// A Check In opens at the before-reading's kind and level, or Pain at 0 when the dose has none.
    func checkInDraft(now: Date) -> EntryDraft {
        var draft = EntryDraft(severity: before?.severity ?? Severity(0)!, date: now)
        draft.kind = checkInKind
        return draft
    }
}
