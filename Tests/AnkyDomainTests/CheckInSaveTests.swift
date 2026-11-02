// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct CheckInSaveTests {
    private let takenAt = Date(timeIntervalSince1970: 1_800_000_000)

    private func dose() -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt)
    }

    private func draft(date: Date) -> EntryDraft {
        var draft = EntryDraft(severity: Severity(2)!, date: date)
        draft.kind = .fatigue
        return draft
    }

    @Test func theEntryIsAddedBeforeTheDosePointsAtIt() throws {
        var events: [String] = []
        var added: [Entry] = []
        var replaced: [Dose] = []
        var save = CheckInSave()
        // A check-in dated before the dose is saved as asked.
        let earlier = draft(date: takenAt.addingTimeInterval(-600))
        let original = dose()

        let saved = try save.save(
            earlier, for: original,
            addEntry: { added.append($0); events.append("entry") },
            replaceDose: { replaced.append($0); events.append("dose") }
        )

        #expect(saved)
        #expect(events == ["entry", "dose"])
        let entry = try #require(added.first)
        #expect(entry.kind == .fatigue)
        #expect(entry.severity == earlier.severity)
        #expect(entry.date == earlier.date)
        #expect(entry.places.isEmpty)
        #expect(replaced.first?.id == original.id)
        #expect(replaced.first?.afterReadingID == entry.id)
    }

    @Test func aRefusedEntryWriteStoresNothingAndKeepsTheSaveOpen() throws {
        var added: [Entry] = []
        var replaced: [Dose] = []
        var refuse = true
        var save = CheckInSave()
        let pending = draft(date: takenAt)
        let original = dose()

        #expect(throws: Refused.no) {
            try save.save(pending, for: original, addEntry: { entry in
                if refuse {
                    throw Refused.no
                }
                added.append(entry)
            }, replaceDose: { replaced.append($0) })
        }
        #expect(!save.isSaved)
        #expect(added.isEmpty)
        #expect(replaced.isEmpty)

        refuse = false
        #expect(try save.save(
            pending,
            for: original,
            addEntry: { added.append($0) },
            replaceDose: { replaced.append($0) }
        ))
        #expect(added.count == 1)
        #expect(replaced.first?.afterReadingID == added.first?.id)
    }

    @Test func aRefusedDoseWriteKeepsOneEntryAndTheRetryAddsNothingTwice() throws {
        var added: [Entry] = []
        var replaced: [Dose] = []
        var refuse = true
        var save = CheckInSave()
        let pending = draft(date: takenAt)
        let original = dose()

        #expect(throws: Refused.no) {
            try save.save(pending, for: original, addEntry: { added.append($0) }, replaceDose: { _ in
                if refuse {
                    throw Refused.no
                }
            })
        }
        #expect(!save.isSaved)
        #expect(added.count == 1)

        refuse = false
        #expect(try save.save(
            pending,
            for: original,
            addEntry: { added.append($0) },
            replaceDose: { replaced.append($0) }
        ))
        #expect(added.count == 1)
        #expect(replaced.first?.afterReadingID == added.first?.id)
        #expect(save.isSaved)
    }

    @Test func aRefusedSaveReportsNothingAndTheFirstSuccessReportsOnce() throws {
        var save = CheckInSave()
        let pending = draft(date: takenAt)

        #expect(throws: Refused.no) {
            try save.save(pending, for: dose(), addEntry: { _ in throw Refused.no }, replaceDose: { _ in })
        }
        #expect(try save.save(pending, for: dose(), addEntry: { _ in }, replaceDose: { _ in }))
        #expect(try !save.save(pending, for: dose(), addEntry: { _ in }, replaceDose: { _ in }))
    }

    @Test func aSecondSaveAfterASuccessWritesNothing() throws {
        var writes = 0
        var save = CheckInSave()
        let pending = draft(date: takenAt)

        #expect(try save.save(pending, for: dose(), addEntry: { _ in writes += 1 }, replaceDose: { _ in writes += 1 }))
        #expect(try !save.save(pending, for: dose(), addEntry: { _ in writes += 1 }, replaceDose: { _ in writes += 1 }))
        #expect(writes == 2)
    }
}

private enum Refused: Error {
    case no
}
