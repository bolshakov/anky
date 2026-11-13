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

    @Test func aRetryAfterARefusedDoseWriteKeepsTheFirstSeverityKindAndDate() throws {
        let first = draft(date: takenAt)
        var retry = try EntryDraft(severity: #require(Severity(7)), date: takenAt.addingTimeInterval(3600))
        retry.kind = .stiffness

        let retried = try saveRetried(first, then: retry)

        #expect(retried.added.count == 1)
        let entry = try #require(retried.added.first)
        #expect(entry.severity == first.severity)
        #expect(entry.kind == .fatigue)
        #expect(entry.date == first.date)
        #expect(retried.replaced.first?.afterReadingID == entry.id)
        #expect(retried.isSaved)
    }

    @Test func aRetryAfterARefusedDoseWriteKeepsTheFirstPlaces() throws {
        let neck = PlaceID(rawValue: "neck")
        var first = try EntryDraft(severity: #require(Severity(3)), date: takenAt)
        first.kind = .stiffness
        first.places = [neck]
        var retry = first
        retry.places = [PlaceID(rawValue: "jaw"), PlaceID(rawValue: "lower")]

        let retried = try saveRetried(first, then: retry)

        #expect(retried.added.count == 1)
        let entry = try #require(retried.added.first)
        #expect(entry.places == [neck])
        #expect(retried.replaced.first?.afterReadingID == entry.id)
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

    /// Switching to Fatigue keeps the places the draft holds, since Check In shows them again on switching back. Only a
    /// kind that asks where saves them.
    @Test func aStiffnessCheckInSavesItsPlacesAndAFatigueOneSavesNone() throws {
        let neck = PlaceID(rawValue: "neck")
        var pending = try EntryDraft(severity: #require(Severity(3)), date: takenAt)
        pending.kind = .stiffness
        pending.places = [neck]

        pending.kind = .fatigue
        #expect(pending.places == [neck])
        let fatigue = try savedEntry(for: pending)
        #expect(fatigue.places.isEmpty)

        pending.kind = .stiffness
        let stiffness = try savedEntry(for: pending)
        #expect(stiffness.places == [neck])
    }

    private func savedEntry(for pending: EntryDraft) throws -> Entry {
        var added: [Entry] = []
        var save = CheckInSave()
        _ = try save.save(pending, for: dose(), addEntry: { added.append($0) }, replaceDose: { _ in })
        return try #require(added.first)
    }

    /// Saves `first` with a refused dose write, then retries on the same save with `retry` and a dose write that works.
    private func saveRetried(_ first: EntryDraft, then retry: EntryDraft) throws -> Retried {
        var added: [Entry] = []
        var replaced: [Dose] = []
        var save = CheckInSave()
        let original = dose()

        #expect(throws: Refused.no) {
            try save.save(first, for: original, addEntry: { added.append($0) }, replaceDose: { _ in throw Refused.no })
        }
        _ = try save.save(retry, for: original, addEntry: { added.append($0) }, replaceDose: { replaced.append($0) })
        return Retried(added: added, replaced: replaced, isSaved: save.isSaved)
    }
}

private struct Retried {
    let added: [Entry]
    let replaced: [Dose]
    let isSaved: Bool
}

private enum Refused: Error {
    case no
}
