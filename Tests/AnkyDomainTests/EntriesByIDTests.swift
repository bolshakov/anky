// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EntriesByIDTests {
    private let takenAt = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func entry(id: UUID = UUID(), _ kind: EntryKind = .pain, severity: Int = 4) throws -> Entry {
        try Entry(id: id, kind: kind, severity: #require(Severity(severity)), date: takenAt, note: nil, places: [])
    }

    private func dose(before: UUID? = nil, after: UUID? = nil) -> Dose {
        var dose = Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt, beforeReadingID: before)
        dose.afterReadingID = after
        return dose
    }

    @Test func anIdFindsItsEntryAndAnUnknownIdFindsNone() throws {
        let kept = try entry(severity: 6)
        let index = try EntriesByID([kept, entry(severity: 2)])
        #expect(index[kept.id] == kept)
        #expect(index[UUID()] == nil)
    }

    @Test func anEmptyLogFindsNothing() {
        #expect(EntriesByID([])[UUID()] == nil)
    }

    @Test func onARepeatedIdTheFirstEntryInSaveOrderWins() throws {
        let id = UUID()
        let first = try entry(id: id, .pain, severity: 3)
        let second = try entry(id: id, .stiffness, severity: 8)
        #expect(EntriesByID([first, second])[id] == first)
        #expect(EntriesByID([second, first])[id] == second)
    }

    @Test func aDoseReadsTheSameThroughTheIndexAsThroughTheWholeLog() throws {
        let beforeID = UUID()
        let afterID = UUID()
        let log = try [entry(severity: 1), entry(id: beforeID, .pain, severity: 5), entry(id: afterID, .fatigue)]
            + [entry(id: beforeID, .stiffness, severity: 9), entry(id: afterID, .pain, severity: 2)]
        let doses = [dose(before: beforeID, after: afterID), dose(before: beforeID), dose(after: UUID()), dose()]
        let index = EntriesByID(log)
        for dose in doses {
            #expect(DoseReadings(dose, in: index) == DoseReadings(dose, in: log))
        }
    }

    @Test func aRepeatedIdReadsAsTheFirstEntryForADose() throws {
        let id = UUID()
        let first = try entry(id: id, severity: 3)
        let second = try entry(id: id, severity: 8)
        let readings = DoseReadings(dose(before: id), in: EntriesByID([first, second]))
        #expect(readings.before == first)
    }
}
