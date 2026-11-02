// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseReadingsTests {
    private let takenAt = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func entry(_ kind: EntryKind = .pain, severity: Int = 4) throws -> Entry {
        try Entry(id: UUID(), kind: kind, severity: #require(Severity(severity)), date: takenAt, note: nil, places: [])
    }

    private func dose(before: UUID? = nil, after: UUID? = nil) -> Dose {
        var dose = Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt, beforeReadingID: before)
        dose.afterReadingID = after
        return dose
    }

    @Test func theIdsResolveToTheEntriesTheyNameAndNotToOthers() throws {
        let before = try entry(severity: 6)
        let after = try entry(.stiffness, severity: 3)
        let other = try entry(severity: 9)
        let readings = DoseReadings(dose(before: before.id, after: after.id), in: [other, after, before])
        #expect(readings.before == before)
        #expect(readings.after == after)
    }

    @Test func aDoseWithNoIdsHasNoReadings() throws {
        let readings = try DoseReadings(dose(), in: [entry()])
        #expect(readings.before == nil)
        #expect(readings.after == nil)
    }

    @Test func anIdThatMatchesNoEntryReadsAsNoReading() throws {
        let kept = try entry(severity: 6)
        let readings = DoseReadings(dose(before: UUID(), after: kept.id), in: [kept])
        #expect(readings.before == nil)
        #expect(readings.after == kept)
    }

    @Test func aReadingSharedByTwoDosesReadsForEachOfThem() throws {
        let shared = try entry(severity: 5)
        let first = dose(before: shared.id)
        let second = dose(before: shared.id)
        #expect(DoseReadings(first, in: [shared]).before == shared)
        #expect(DoseReadings(second, in: [shared]).before == shared)
    }
}
