// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct LogDosePickingTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_030)
    private let asNeeded = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: .distantPast)

    private func entry(minutesBack: Double) throws -> Entry {
        try Entry(
            id: UUID(), kind: .pain, severity: #require(Severity(4)), date: now.addingTimeInterval(-minutesBack * 60),
            note: nil, places: []
        )
    }

    private func resolved(_ draft: LogDoseDraft, entries: [Entry]) -> UUID? {
        ReadingLink.resolve(
            linked: draft.linkedReadingID, manual: draft.manualReadingID, noReading: draft.noReading,
            in: entries, at: now
        )?.id
    }

    private func linked(_ entry: Entry) -> LogDoseDraft {
        var draft = LogDoseDraft.untouched(preselected: asNeeded.id, active: [asNeeded])
        draft.linkedReadingID = entry.id
        return draft
    }

    @Test func pickingTheLinkedEntryOutsideTheWindowKeepsIt() throws {
        let outside = try entry(minutesBack: 180)
        let inside = try entry(minutesBack: 10)
        let picked = linked(outside).picking(outside.id)
        #expect(resolved(picked, entries: [outside, inside]) == outside.id)
    }

    @Test func pickingAnotherEntryReplacesTheLink() throws {
        let outside = try entry(minutesBack: 180)
        let inside = try entry(minutesBack: 10)
        let picked = linked(outside).picking(inside.id)
        #expect(resolved(picked, entries: [outside, inside]) == inside.id)
    }

    @Test func pickingAnEntryWithNothingLinkedChoosesIt() throws {
        let older = try entry(minutesBack: 60)
        let newer = try entry(minutesBack: 10)
        let draft = LogDoseDraft.untouched(preselected: asNeeded.id, active: [asNeeded]).picking(older.id)
        #expect(resolved(draft, entries: [older, newer]) == older.id)
    }

    @Test func pickingLeavesNoneAndMarksTheReadingTouched() throws {
        let inside = try entry(minutesBack: 10)
        var draft = LogDoseDraft.untouched(preselected: asNeeded.id, active: [asNeeded])
        draft.noReading = true
        let picked = draft.picking(inside.id)
        #expect(!picked.noReading)
        #expect(picked.readingTouched)
    }
}
