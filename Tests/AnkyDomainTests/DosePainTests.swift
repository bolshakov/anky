// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DosePainTests {
    private func readings(before: Entry?, after: Entry?) -> DoseReadings {
        var dose = Dose(id: UUID(), medicationID: UUID(), takenAt: Date(), beforeReadingID: before?.id)
        dose.afterReadingID = after?.id
        return DoseReadings(dose, in: [before, after].compactMap(\.self))
    }

    private func entry(_ kind: EntryKind, severity: Int) throws -> Entry {
        try Entry(id: UUID(), kind: kind, severity: #require(Severity(severity)), date: Date(), note: nil, places: [])
    }

    @Test func noReadingsGivesNoPain() {
        #expect(DosePain(readings(before: nil, after: nil)) == nil)
    }

    @Test func aBeforeReadingAloneIsTheBeforePain() throws {
        let before = try entry(.stiffness, severity: 6)
        #expect(try DosePain(readings(before: before, after: nil)) == .before(.stiffness, #require(Severity(6))))
    }

    @Test func anAfterReadingAloneIsTheAfterPain() throws {
        let after = try entry(.fatigue, severity: 2)
        #expect(try DosePain(readings(before: nil, after: after)) == .after(.fatigue, #require(Severity(2))))
    }

    @Test func bothReadingsGiveBeforeAndAfterWithTheKindOfTheBeforeReading() throws {
        let before = try entry(.pain, severity: 6)
        let after = try entry(.stiffness, severity: 3)
        let pain = DosePain(readings(before: before, after: after))
        #expect(try pain == .beforeAndAfter(.pain, before: #require(Severity(6)), after: #require(Severity(3))))
    }
}
