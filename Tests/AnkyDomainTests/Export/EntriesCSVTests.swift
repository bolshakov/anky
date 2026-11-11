// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EntriesCSVTests {
    private let morning = Date(timeIntervalSince1970: 1_762_848_900)

    private func entry(
        id: String = "00000000-0000-0000-0000-000000000001",
        kind: EntryKind = .pain,
        severity: Int = 6,
        at date: Date? = nil,
        note: String? = nil,
        places: [PlaceID] = []
    ) throws -> Entry {
        try Entry(
            id: #require(UUID(uuidString: id)),
            kind: kind,
            severity: #require(Severity(severity)),
            date: date ?? morning,
            note: note,
            places: places
        )
    }

    private func idEnding(_ last: String) -> String {
        "00000000-0000-0000-0000-00000000000" + last
    }

    @Test func namesItsColumnsInOrder() {
        #expect(EntriesCSV.header == ["id", "time", "kind", "severity", "places", "note"])
    }

    @Test func writesOnlyTheHeaderForAnEmptyLog() {
        #expect(EntriesCSV.table([]).text == "id,time,kind,severity,places,note\n")
    }

    @Test func writesEachFieldOfAnEntry() throws {
        let places = [PlaceID(rawValue: "knee_l"), PlaceID(rawValue: "lower_back")]
        let row = try EntriesCSV.table([entry(note: "Walk note", places: places)]).rows[0]
        let id = "00000000-0000-0000-0000-000000000001"
        #expect(row[..<3] == [.text(id), .text("2025-11-11T08:15:00Z"), .text("pain")])
        #expect(row[3...] == [.number(6), .text("knee_l;lower_back"), .text("Walk note")])
    }

    @Test func leavesPlacesAndNoteEmptyWhenTheEntryHasNone() throws {
        let row = try EntriesCSV.table([entry(kind: .fatigue, severity: 0)]).rows[0]
        #expect(row[2...] == [.text("fatigue"), .number(0), .empty, .empty])
    }

    @Test func leavesAnEmptyNoteEmpty() throws {
        #expect(try EntriesCSV.table([entry(note: "")]).rows[0][5] == .empty)
    }

    @Test(arguments: ["Hurt, \"a lot\"\nTëma Бехтерев", "one\r\ntwo", "one\rtwo"])
    func keepsANoteAsOneCellWithItsLineBreaks(note: String) throws {
        let text = try EntriesCSV.table([entry(note: note)]).text
        let quoted = "\"" + note.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        #expect(text.hasSuffix(",\(quoted)\n"))
    }

    @Test func ordersRowsByTimeThenByID() throws {
        let later = morning.addingTimeInterval(60)
        let entries = try [("B", later), ("C", morning), ("A", morning)].map { try entry(id: idEnding($0), at: $1) }
        let ids = EntriesCSV.table(entries).rows.map { $0[0] }
        let expected = ["A", "C", "B"].map { CSVCell.text(idEnding($0)) }
        #expect(ids == expected)
    }

    @Test func ordersTwoEntriesInTheSamePrintedSecondByID() throws {
        let entries = try [("B", 5.1), ("A", 5.9)].map { try entry(id: idEnding($0), at: morning + $1) }
        let ids = EntriesCSV.table(entries).rows.map { $0[0] }
        #expect(ids == [.text(idEnding("A")), .text(idEnding("B"))])
    }

    @Test func printsATimeWithFractionalSecondsWhole() throws {
        let row = try EntriesCSV.table([entry(at: morning.addingTimeInterval(5.75))]).rows[0]
        #expect(row[1] == .text("2025-11-11T08:15:05Z"))
    }
}
