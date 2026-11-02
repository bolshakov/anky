// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct CheckInDraftTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ kind: EntryKind, _ level: Int) -> Entry {
        Entry(id: UUID(), kind: kind, severity: Severity(level)!, date: now, note: nil, places: [])
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
