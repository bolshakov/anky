// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportMedicationsTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    /// Wednesday 11 November 2026, 15:00. A month back starts on 11 October, so the period has 32 calendar days.
    private var now: Date {
        get throws { try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 15))) }
    }

    private var start: Date {
        get throws { try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) }
    }

    private func daysAgo(_ days: Double) throws -> Date {
        try now.addingTimeInterval(-days * 86400)
    }

    private func medication(_ name: String, _ takenAs: TakenAs = .asNeeded, id: UUID = UUID()) throws -> Medication {
        try Medication(id: id, name: name, takenAs: takenAs, createdAt: daysAgo(200))
    }

    private func entry(_ severity: Int, at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: .pain, severity: #require(Severity(severity)), date: date, note: nil, places: [])
    }

    private func dose(of medication: Medication, at date: Date, before: Entry? = nil, after: Entry? = nil) -> Dose {
        var dose = Dose(id: UUID(), medicationID: medication.id, takenAt: date, beforeReadingID: before?.id)
        dose.afterReadingID = after?.id
        return dose
    }

    private struct Reading {
        let dose: Dose
        let entries: [Entry]
    }

    /// A dose with a before-reading ten minutes ahead of it and an after-reading `minutesLater` after it.
    private func readDose(
        of medication: Medication, at date: Date, pain: (before: Int, after: Int), minutesLater: Double
    ) throws -> Reading {
        let beforeEntry = try entry(pain.before, at: date.addingTimeInterval(-600))
        let afterEntry = try entry(pain.after, at: date.addingTimeInterval(minutesLater * 60))
        return Reading(dose: dose(of: medication, at: date, before: beforeEntry, after: afterEntry),
                       entries: [beforeEntry, afterEntry])
    }

    private func report(
        _ medications: [Medication], _ doses: [Dose], _ entries: [Entry] = []
    ) throws -> ReportMedications {
        try ReportMedications(
            medications: medications, doses: doses, entries: entries, period: .oneMonth, now: now, calendar: calendar
        )
    }

    private func onlyRow(_ report: ReportMedications) throws -> ReportMedicationRow {
        try #require(report.rows.count == 1)
        return report.rows[0]
    }

    @Test func oneMedicationWithDosesGivesExactlyOneRow() throws {
        let zorblex = try medication("Zorblex")
        let doses = try [dose(of: zorblex, at: daysAgo(2)), dose(of: zorblex, at: daysAgo(1))]
        let row = try onlyRow(report([zorblex], doses))
        #expect(row.medication == zorblex)
        #expect(row.doseCount == 2)
    }

    @Test func aMedicationWithNoDoseInThePeriodHasNoRow() throws {
        let zorblex = try medication("Zorblex")
        let quillen = try medication("Quillen")
        let doses = try [dose(of: zorblex, at: daysAgo(1)), dose(of: quillen, at: daysAgo(40))]
        #expect(try report([zorblex, quillen], doses).rows.map(\.medication) == [zorblex])
    }

    @Test func dosesThatAllFallOutsideThePeriodGiveNoRow() throws {
        let zorblex = try medication("Zorblex")
        let dates = try [start.addingTimeInterval(-1), daysAgo(90), now.addingTimeInterval(1)]
        let doses = dates.map { dose(of: zorblex, at: $0) }
        #expect(try report([zorblex], doses).rows.isEmpty)
    }

    @Test func aDoseOnThePeriodsFirstDayAndOneAtNowBothCount() throws {
        let zorblex = try medication("Zorblex")
        let dates = try [start, now, start.addingTimeInterval(-1)]
        let doses = dates.map { dose(of: zorblex, at: $0) }
        #expect(try onlyRow(report([zorblex], doses)).doseCount == 2)
    }

    @Test func anArchivedMedicationWithADoseHasARow() throws {
        var oldpill = try medication("Oldpill")
        oldpill.archivedAt = try daysAgo(3)
        let row = try onlyRow(report([oldpill], [dose(of: oldpill, at: daysAgo(5))]))
        #expect(row.medication == oldpill)
        #expect(row.doseCount == 1)
    }

    @Test func aDoseOfADeletedMedicationAddsNoRow() throws {
        let zorblex = try medication("Zorblex")
        let deleted = try medication("Gone")
        let doses = try [dose(of: deleted, at: daysAgo(1)), dose(of: zorblex, at: daysAgo(1))]
        #expect(try report([zorblex], doses).rows.map(\.medication) == [zorblex])
    }

    @Test func rowsRunFromMostDosesToFewest() throws {
        let few = try medication("Alpha")
        let many = try medication("Beta")
        let doses = try [dose(of: few, at: daysAgo(1))] + (1 ... 3).map { try dose(of: many, at: daysAgo(Double($0))) }
        #expect(try report([few, many], doses).rows.map(\.medication.name) == ["Beta", "Alpha"])
    }

    @Test func aTieOnDosesReadsByNameWhateverTheInputOrder() throws {
        let marvex = try medication("Marvex")
        let quillen = try medication("Quillen")
        let doses = try [dose(of: quillen, at: daysAgo(1)), dose(of: marvex, at: daysAgo(2))]
        #expect(try report([quillen, marvex], doses).rows.map(\.medication.name) == ["Marvex", "Quillen"])
        #expect(try report([marvex, quillen], doses.reversed()).rows.map(\.medication.name) == ["Marvex", "Quillen"])
    }

    @Test func aTieOnDosesAndNameReadsById() throws {
        let low = try medication("Zorblex", id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001")))
        let high = try medication("Zorblex", id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002")))
        let doses = try [dose(of: high, at: daysAgo(1)), dose(of: low, at: daysAgo(1))]
        #expect(try report([high, low], doses).rows.map(\.medication.id) == [low.id, high.id])
    }

    @Test func perWeekDividesDosesByTheWeeksInThePeriod() throws {
        let marvex = try medication("Marvex")
        let doses = try (1 ... 4).map { try dose(of: marvex, at: daysAgo(Double($0))) }
        #expect(try abs(onlyRow(report([marvex], doses)).perWeek - 0.875) < 1e-9)
    }

    @Test func handWorkedFiguresUseOnlyDosesWithBothReadings() throws {
        let zorblex = try medication("Zorblex")
        let first = try readDose(of: zorblex, at: daysAgo(20), pain: (6, 3), minutesLater: 90)
        let second = try readDose(of: zorblex, at: daysAgo(15), pain: (7, 4), minutesLater: 120)
        let third = try readDose(of: zorblex, at: daysAgo(10), pain: (5, 2), minutesLater: 110)
        let fourth = try readDose(of: zorblex, at: daysAgo(5), pain: (8, 5), minutesLater: 120)
        let read = [first, second, third, fourth]
        let onlyBefore = try entry(9, at: daysAgo(2))
        let doses = try read.map(\.dose) + [dose(of: zorblex, at: daysAgo(2), before: onlyBefore)]
        let row = try onlyRow(report([zorblex], doses, read.flatMap(\.entries) + [onlyBefore]))
        #expect(row.doseCount == 5)
        #expect(row.afterReadingCount == 4)
        #expect(row.before == ReportPainRange(average: 6.5, lowest: 5, highest: 8, count: 4))
        #expect(row.after == ReportPainRange(average: 3.5, lowest: 2, highest: 5, count: 4))
        #expect(row.averageTimeToAfter == TimeInterval(110 * 60))
    }

    @Test func oneQualifyingDoseGivesItsOwnValuesAsLowestAndHighest() throws {
        let quillen = try medication("Quillen")
        let read = try readDose(of: quillen, at: daysAgo(4), pain: (6, 3), minutesLater: 45)
        let doses = try [read.dose, dose(of: quillen, at: daysAgo(3))]
        let row = try onlyRow(report([quillen], doses, read.entries))
        #expect(row.afterReadingCount == 1)
        #expect(row.before == ReportPainRange(average: 6, lowest: 6, highest: 6, count: 1))
        #expect(row.after == ReportPainRange(average: 3, lowest: 3, highest: 3, count: 1))
        #expect(row.averageTimeToAfter == TimeInterval(45 * 60))
    }

    @Test func noQualifyingDoseGivesNoPainAndNoTime() throws {
        let marvex = try medication("Marvex", .scheduled)
        let before = try entry(5, at: daysAgo(3))
        let after = try entry(2, at: daysAgo(1))
        let onlyBefore = try dose(of: marvex, at: daysAgo(3), before: before)
        let onlyAfter = try dose(of: marvex, at: daysAgo(2), after: after)
        let doses = [onlyBefore, onlyAfter]
        let row = try onlyRow(report([marvex], doses, [before, after]))
        #expect(row.afterReadingCount == 1)
        #expect(row.before == nil)
        #expect(row.after == nil)
        #expect(row.averageTimeToAfter == nil)
    }

    @Test func aDeletedReadingCountsAsNoReading() throws {
        let zorblex = try medication("Zorblex")
        let deletedAfter = try readDose(of: zorblex, at: daysAgo(4), pain: (6, 3), minutesLater: 60)
        let deletedBefore = try readDose(of: zorblex, at: daysAgo(3), pain: (7, 4), minutesLater: 60)
        let entries = [deletedAfter.entries[0], deletedBefore.entries[1]]
        let row = try onlyRow(report([zorblex], [deletedAfter.dose, deletedBefore.dose], entries))
        #expect(row.doseCount == 2)
        #expect(row.afterReadingCount == 1)
        #expect(row.before == nil)
        #expect(row.after == nil)
        #expect(row.averageTimeToAfter == nil)
    }

    @Test func anAfterReadingDatedBeforeItsDoseGivesAZeroGap() throws {
        let zorblex = try medication("Zorblex")
        let early = try readDose(of: zorblex, at: daysAgo(4), pain: (6, 3), minutesLater: -30)
        let late = try readDose(of: zorblex, at: daysAgo(3), pain: (6, 3), minutesLater: 60)
        let row = try onlyRow(report([zorblex], [early.dose, late.dose], early.entries + late.entries))
        #expect(row.averageTimeToAfter == TimeInterval(30 * 60))
    }

    @Test func hasScheduledIsTrueOnlyWhenARowsMedicationIsScheduled() throws {
        let zorblex = try medication("Zorblex")
        let marvex = try medication("Marvex", .scheduled)
        #expect(try report([zorblex, marvex], [dose(of: marvex, at: daysAgo(1))]).hasScheduled)
        #expect(try !report([zorblex, marvex], [dose(of: zorblex, at: daysAgo(1))]).hasScheduled)
        #expect(try !report([zorblex, marvex], [dose(of: marvex, at: daysAgo(40))]).hasScheduled)
    }
}
