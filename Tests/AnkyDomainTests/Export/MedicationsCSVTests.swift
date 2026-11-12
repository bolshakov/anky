// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct MedicationsCSVTests {
    private let morning = Date(timeIntervalSince1970: 1_762_848_900)
    private let firstID = "00000000-0000-0000-0000-000000000001"

    private func idEnding(_ last: String) -> String {
        "00000000-0000-0000-0000-00000000000" + last
    }

    private func medication(
        id: String? = nil,
        takenAs: TakenAs = .asNeeded,
        createdAt: Date? = nil,
        schedule: MedicationSchedule? = nil
    ) throws -> Medication {
        var medication = try Medication(
            id: #require(UUID(uuidString: id ?? firstID)),
            name: "Zorblex",
            takenAs: takenAs,
            createdAt: createdAt ?? morning
        )
        medication.schedule = schedule
        return medication
    }

    private func schedule(
        _ repetition: ScheduleRepeat,
        times: [(Int, Int)] = [(8, 5)],
        end: ScheduleDay? = nil
    ) throws -> MedicationSchedule {
        try MedicationSchedule(
            repeat: repetition,
            times: times.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) },
            start: #require(ScheduleDay(year: 2025, month: 3, day: 4)),
            end: end
        )
    }

    private func scheduleColumns(_ medication: Medication) -> ArraySlice<CSVCell> {
        MedicationsCSV.table([medication]).rows[0][8...]
    }

    @Test func namesItsColumnsInOrder() {
        let named = ["id", "created_at", "updated_at", "name", "strength", "how_taken", "check_in_delay_minutes"]
        let schedule = ["repeat_unit", "repeat_every", "weekdays", "day_of_month", "times", "starts", "ends"]
        #expect(MedicationsCSV.header == named + ["archived_at"] + schedule)
    }

    @Test func writesOnlyTheHeaderForNoMedications() {
        let header = "id,created_at,updated_at,name,strength,how_taken,check_in_delay_minutes,archived_at,"
            + "repeat_unit,repeat_every,weekdays,day_of_month,times,starts,ends\n"
        #expect(MedicationsCSV.table([]).text == header)
    }

    @Test func writesAnAsNeededMedicationWithEmptyOptionalAndScheduleColumns() throws {
        let row = try MedicationsCSV.table([medication()]).rows[0]
        let time = CSVCell.text("2025-11-11T08:15:00Z")
        #expect(row[..<4] == [.text(firstID), time, time, .text("Zorblex")])
        #expect(row[4...] == [.empty, .text("as_needed"), .empty, .empty] + Array(repeating: .empty, count: 7))
    }

    @Test func writesStrengthDelayUpdateAndArchiveTimes() throws {
        var archived = try medication()
        archived.strength = "50 mg"
        archived.checkInAfter = .twoHours
        archived.updatedAt = morning.addingTimeInterval(60)
        archived.archivedAt = morning.addingTimeInterval(120)
        let row = MedicationsCSV.table([archived]).rows[0]
        #expect(row[2] == .text("2025-11-11T08:16:00Z"))
        #expect(row[4 ..< 8] == [.text("50 mg"), .text("as_needed"), .number(120), .text("2025-11-11T08:17:00Z")])
    }

    @Test func keepsANameAndStrengthWithACommaAndAQuoteAsOneCellEach() throws {
        var odd = try medication()
        odd.name = "Walk, \"A\""
        odd.strength = "5, \"or\" 10 mg"
        let records = try CSVReader.records(MedicationsCSV.table([odd]).text)
        #expect(records.last?.count == 15)
        #expect(records.last?[3 ... 4] == ["Walk, \"A\"", "5, \"or\" 10 mg"])
    }

    @Test func writesADailyScheduleWithItsTimesAndNoEnd() throws {
        let daily = try schedule(.days(2), times: [(8, 5), (21, 30)])
        let columns = try scheduleColumns(medication(takenAs: .scheduled, schedule: daily))
        let expected: [CSVCell] = [.text("days"), .number(2), .empty, .empty, .text("08:05;21:30")]
        #expect(columns == ArraySlice(expected + [.text("2025-03-04"), .empty]))
    }

    @Test func writesAWeeklyScheduleWithWeekdaysFromMondayWhateverTheSetOrder() throws {
        let end = try #require(ScheduleDay(year: 2026, month: 1, day: 9))
        let weekly = try schedule(.weeks(1, on: [.sunday, .wednesday, .monday, .saturday]), end: end)
        let columns = try scheduleColumns(medication(takenAs: .scheduled, schedule: weekly))
        let expected: [CSVCell] = [.text("weeks"), .number(1), .text("mon;wed;sat;sun"), .empty, .text("08:05")]
        #expect(columns == ArraySlice(expected + [.text("2025-03-04"), .text("2026-01-09")]))
    }

    @Test func spellsEveryWeekdayInMondayToSundayOrder() throws {
        let every = try schedule(.weeks(3, on: [.saturday, .friday, .thursday, .wednesday, .tuesday, .monday, .sunday]))
        let columns = try scheduleColumns(medication(takenAs: .scheduled, schedule: every))
        #expect(columns[10] == .text("mon;tue;wed;thu;fri;sat;sun"))
    }

    @Test func writesAMonthlyScheduleWithItsDayOfMonth() throws {
        let monthly = try schedule(.months(1, onDay: 31))
        let columns = try scheduleColumns(medication(takenAs: .scheduled, schedule: monthly))
        let expected: [CSVCell] = [.text("months"), .number(1), .empty, .number(31), .text("08:05")]
        #expect(columns == ArraySlice(expected + [.text("2025-03-04"), .empty]))
    }

    @Test func leavesScheduleColumnsEmptyForAScheduledMedicationWithNoSchedule() throws {
        let row = try MedicationsCSV.table([medication(takenAs: .scheduled)]).rows[0]
        #expect(row[5] == .text("scheduled"))
        #expect(row[8...] == ArraySlice(Array(repeating: .empty, count: 7)))
    }

    @Test func leavesScheduleColumnsEmptyForAnAsNeededMedicationThatKeptAnOldSchedule() throws {
        let columns = try scheduleColumns(medication(takenAs: .asNeeded, schedule: schedule(.days(1))))
        #expect(columns == ArraySlice(Array(repeating: .empty, count: 7)))
    }

    @Test func keepsArchivedMedicationsAndOrdersRowsByCreatedAtThenID() throws {
        let later = morning.addingTimeInterval(60)
        var medications = try [("B", later), ("C", morning), ("A", morning)].map {
            try medication(id: idEnding($0), createdAt: $1)
        }
        medications[1].archivedAt = later
        let ids = MedicationsCSV.table(medications).rows.map { $0[0] }
        #expect(ids == ["A", "C", "B"].map { CSVCell.text(idEnding($0)) })
    }

    @Test func ordersTwoMedicationsCreatedInTheSamePrintedSecondByID() throws {
        let medications = try [("B", 5.1), ("A", 5.9)].map { try medication(id: idEnding($0), createdAt: morning + $1) }
        let ids = MedicationsCSV.table(medications).rows.map { $0[0] }
        #expect(ids == [.text(idEnding("A")), .text(idEnding("B"))])
    }
}
