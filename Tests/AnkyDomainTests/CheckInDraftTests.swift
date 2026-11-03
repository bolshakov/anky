// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct CheckInDraftTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let lower = PlaceID(rawValue: "lower")
    private let neck = PlaceID(rawValue: "neck")

    private func entry(_ kind: EntryKind, _ level: Int, places: [PlaceID] = []) -> Entry {
        Entry(id: UUID(), kind: kind, severity: Severity(level)!, date: now, note: nil, places: places)
    }

    private func readings(pointingAt beforeID: UUID?, in entries: [Entry]) -> DoseReadings {
        let dose = Dose(id: UUID(), medicationID: UUID(), takenAt: now, beforeReadingID: beforeID)
        return DoseReadings(dose, in: entries)
    }

    @Test func startsAtTheBeforeReadingsKindAndLevel() {
        let fatigue = entry(.fatigue, 5)
        let draft = readings(pointingAt: fatigue.id, in: [fatigue]).checkInDraft(now: now)

        #expect(draft.kind == .fatigue)
        #expect(draft.severity == fatigue.severity)
        #expect(draft.date == now)
        #expect(draft.places.isEmpty)
    }

    @Test func startsWithTheBeforeReadingsPlaces() {
        let pain = entry(.pain, 6, places: [neck, lower])
        let draft = readings(pointingAt: pain.id, in: [pain]).checkInDraft(now: now)

        #expect(draft.places == pain.places)
    }

    @Test func aSavedCheckInKeepsTheBeforeReadingsPlaces() throws {
        let pain = entry(.pain, 6, places: [neck, lower])
        let dose = Dose(id: UUID(), medicationID: UUID(), takenAt: now, beforeReadingID: pain.id)
        let draft = DoseReadings(dose, in: [pain]).checkInDraft(now: now)
        var added: [Entry] = []
        var save = CheckInSave()

        _ = try save.save(draft, for: dose, addEntry: { added.append($0) }, replaceDose: { _ in })

        #expect(added.first?.places == pain.places)
    }

    /// Check In shows the Where row only when the draft's kind asks where.
    @Test func aFatigueCheckInHasNoWhereRow() {
        let fatigue = entry(.fatigue, 5)
        let draft = readings(pointingAt: fatigue.id, in: [fatigue]).checkInDraft(now: now)

        #expect(draft.kind == .fatigue)
        #expect(!draft.kind.asksWhere)
    }

    @Test func startsAtPainAtZeroWithNoBeforeReading() {
        let draft = readings(pointingAt: nil, in: []).checkInDraft(now: now)

        #expect(draft.kind == .pain)
        #expect(draft.severity == Severity(0))
    }

    @Test func aDeletedBeforeReadingStartsAsIfThereWasNone() {
        let draft = readings(pointingAt: UUID(), in: [entry(.stiffness, 4)]).checkInDraft(now: now)

        #expect(draft.kind == .pain)
        #expect(draft.severity == Severity(0))
    }
}
