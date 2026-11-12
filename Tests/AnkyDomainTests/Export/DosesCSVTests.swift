// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DosesCSVTests {
    private let morning = Date(timeIntervalSince1970: 1_762_848_900)
    private let medicationID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")
    private let beforeID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")
    private let afterID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")

    private func idEnding(_ last: String) -> String {
        "00000000-0000-0000-0000-00000000000" + last
    }

    private func dose(id: String = "00000000-0000-0000-0000-000000000001", at date: Date? = nil) throws -> Dose {
        var dose = try Dose(
            id: #require(UUID(uuidString: id)),
            medicationID: #require(medicationID),
            takenAt: date ?? morning
        )
        dose.loggedAt = morning.addingTimeInterval(30)
        return dose
    }

    private func reading(_ id: UUID?, severity: Int, at date: Date) throws -> Entry {
        let severity = try #require(Severity(severity))
        return try Entry(id: #require(id), kind: .pain, severity: severity, date: date, note: nil, places: [])
    }

    private func readings() throws -> [Entry] {
        let before = try reading(beforeID, severity: 7, at: morning.addingTimeInterval(-600))
        return try [before, reading(afterID, severity: 3, at: morning.addingTimeInterval(3600))]
    }

    @Test func namesItsColumnsInOrder() {
        let header = ["id", "logged_at", "medication_id", "time_taken", "pain_before", "pain_after", "after_time"]
        #expect(DosesCSV.header == header)
    }

    @Test func writesOnlyTheHeaderForNoDoses() throws {
        let header = "id,logged_at,medication_id,time_taken,pain_before,pain_after,after_time\n"
        #expect(try DosesCSV.table([], entries: readings()).text == header)
    }

    @Test func writesADoseWithThePainAndTimeOfBothReadings() throws {
        var both = try dose()
        both.beforeReadingID = beforeID
        both.afterReadingID = afterID
        let row = try DosesCSV.table([both], entries: readings()).rows[0]
        let medication = try CSVCell.text(#require(medicationID).uuidString)
        #expect(row[..<3] == [.text("00000000-0000-0000-0000-000000000001"), .text("2025-11-11T08:15:30Z"), medication])
        #expect(row[3] == .text("2025-11-11T08:15:00Z"))
        #expect(row[4...] == [.number(7), .number(3), .text("2025-11-11T09:15:00Z")])
    }

    @Test func leavesPainEmptyWhenTheDoseNamesNoReadings() throws {
        let row = try DosesCSV.table([dose()], entries: readings()).rows[0]
        #expect(row[4...] == [.empty, .empty, .empty])
    }

    @Test func leavesPainAndAfterTimeEmptyWhenTheNamedReadingsWereDeleted() throws {
        var orphan = try dose()
        orphan.beforeReadingID = beforeID
        orphan.afterReadingID = afterID
        let row = DosesCSV.table([orphan], entries: []).rows[0]
        #expect(row[4...] == [.empty, .empty, .empty])
    }

    @Test func writesAZeroBeforeReadingAsZeroWithNoAfterReading() throws {
        var calm = try dose()
        calm.beforeReadingID = beforeID
        let entries = try [reading(beforeID, severity: 0, at: morning)]
        let row = DosesCSV.table([calm], entries: entries).rows[0]
        #expect(row[4...] == [.number(0), .empty, .empty])
    }

    @Test func writesADoseWithNoLoggedAtWithAnEmptyLoggedAt() throws {
        var old = try dose()
        old.loggedAt = nil
        let rows = try DosesCSV.table([old], entries: readings()).rows
        #expect(rows.count == 1)
        #expect(rows[0][1] == .empty)
        #expect(rows[0][3] == .text("2025-11-11T08:15:00Z"))
    }

    @Test func ordersRowsByTimeTakenThenByID() throws {
        let later = morning.addingTimeInterval(60)
        let doses = try [("B", later), ("C", morning), ("A", morning)].map { try dose(id: idEnding($0), at: $1) }
        let ids = DosesCSV.table(doses, entries: []).rows.map { $0[0] }
        #expect(ids == ["A", "C", "B"].map { CSVCell.text(idEnding($0)) })
    }

    @Test func ordersTwoDosesTakenInTheSamePrintedSecondByID() throws {
        let doses = try [("B", 5.1), ("A", 5.9)].map { try dose(id: idEnding($0), at: morning + $1) }
        let ids = DosesCSV.table(doses, entries: []).rows.map { $0[0] }
        #expect(ids == [.text(idEnding("A")), .text(idEnding("B"))])
    }
}
