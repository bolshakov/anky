// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct BasdaiCSVTests {
    private let morning = Date(timeIntervalSince1970: 1_762_848_900)

    private func idEnding(_ last: String) -> String {
        "00000000-0000-0000-0000-00000000000" + last
    }

    private func result(
        id: String = "00000000-0000-0000-0000-000000000001",
        at date: Date? = nil,
        answers: [Int] = [4, 6, 3, 5, 7, 4]
    ) throws -> BasdaiResult {
        let id = try #require(UUID(uuidString: id))
        return try #require(BasdaiResult(id: id, date: date ?? morning, answers: answers))
    }

    private func scoreCell(of answers: [Int]) throws -> CSVCell {
        try #require(BasdaiCSV.table([result(answers: answers)]).rows[0].last)
    }

    @Test func namesItsColumnsInOrder() {
        let header = ["id", "created_at", "updated_at", "date", "q1", "q2", "q3", "q4", "q5", "q6", "score"]
        #expect(BasdaiCSV.header == header)
    }

    @Test func writesOnlyTheHeaderForNoResults() {
        #expect(BasdaiCSV.table([]).text == "id,created_at,updated_at,date,q1,q2,q3,q4,q5,q6,score\n")
    }

    @Test func writesAResultWithQuotedIDAndMomentsBareAnswersAndABareScore() throws {
        var saved = try result()
        saved.createdAt = morning.addingTimeInterval(-60)
        saved.updatedAt = morning.addingTimeInterval(30)
        let row = BasdaiCSV.table([saved]).rows[0]
        let moments: [CSVCell] = [.text("2025-11-11T08:14:00Z"), .text("2025-11-11T08:15:30Z")]
        let date: [CSVCell] = [.text("2025-11-11T08:15:00Z")]
        let answers = [4, 6, 3, 5, 7, 4].map { CSVCell.number($0) }
        let expected = [CSVCell.text("00000000-0000-0000-0000-000000000001")] + moments + date + answers +
            [.bare("4.7")]
        #expect(row == expected)
    }

    @Test func writesTheIDInUpperCase() throws {
        let row = try BasdaiCSV.table([result(id: "0a1b2c3d-0000-4000-8000-00000000abcd")]).rows[0]
        #expect(row[0] == .text("0A1B2C3D-0000-4000-8000-00000000ABCD"))
    }

    @Test func writesTheTextOfAResultAsOneLineWithTheScoreUnquoted() throws {
        let text = try BasdaiCSV.table([result()]).text
        let line = "\"00000000-0000-0000-0000-000000000001\",\"2025-11-11T08:15:00Z\",\"2025-11-11T08:15:00Z\","
            + "\"2025-11-11T08:15:00Z\",4,6,3,5,7,4,4.7\n"
        #expect(text == "id,created_at,updated_at,date,q1,q2,q3,q4,q5,q6,score\n" + line)
    }

    @Test(arguments: [([0, 0, 0, 0, 0, 0], "0.0"), ([10, 10, 10, 10, 10, 10], "10.0"),
                      ([4, 6, 3, 5, 7, 4], "4.7"), ([1, 1, 1, 1, 1, 1], "1.0"),
                      ([3, 3, 3, 3, 4, 5], "3.3"), ([10, 10, 10, 10, 10, 0], "9.0")])
    func writesTheScoreWithExactlyOneDecimalAndADot(answers: [Int], expected: String) throws {
        #expect(try scoreCell(of: answers) == .bare(expected))
    }

    @Test func writesTheSharedScoreFunctionsValueForEveryCombinationOfTwoAnswers() throws {
        let posix = Locale(identifier: "en_US_POSIX")
        for first in 0 ... 10 {
            for last in 0 ... 10 {
                let answers = [first, 0, 0, last, 5, 5]
                let saved = try result(answers: answers)
                #expect(try scoreCell(of: answers) == .bare(BasdaiScore.text(of: saved, locale: posix)))
            }
        }
    }

    @Test func writesTheScoreWithADotWhateverLanguageThePhoneUses() throws {
        let comma = Locale(identifier: "de_DE")
        let saved = try result(answers: [3, 3, 3, 3, 4, 5])
        #expect(BasdaiScore.text(of: saved, locale: comma) == "3,3")
        #expect(try scoreCell(of: [3, 3, 3, 3, 4, 5]) == .bare("3.3"))
    }

    @Test func writesALateEveningInAFarEastZoneAsItsUTCMoment() throws {
        let local = try lateEvening(in: "Pacific/Kiritimati")
        let row = try BasdaiCSV.table([result(at: local)]).rows[0]
        #expect(row[3] == .text("2025-11-11T09:30:00Z"))
    }

    @Test func writesALateEveningInAFarWestZoneOnTheNextUTCDay() throws {
        let local = try lateEvening(in: "Pacific/Pago_Pago")
        let row = try BasdaiCSV.table([result(at: local)]).rows[0]
        #expect(row[3] == .text("2025-11-12T10:30:00Z"))
    }

    @Test func ordersRowsByDateThenByID() throws {
        let later = morning.addingTimeInterval(60)
        let results = try [("B", later), ("C", morning), ("A", morning)].map { try result(id: idEnding($0), at: $1) }
        let ids = BasdaiCSV.table(results).rows.map { $0[0] }
        #expect(ids == ["A", "C", "B"].map { CSVCell.text(idEnding($0)) })
    }

    @Test func ordersTwoResultsFromTheSamePrintedSecondByID() throws {
        let results = try [("B", 5.1), ("A", 5.9)].map { try result(id: idEnding($0), at: morning + $1) }
        let ids = BasdaiCSV.table(results).rows.map { $0[0] }
        #expect(ids == [.text(idEnding("A")), .text(idEnding("B"))])
    }

    @Test func includesEveryResultWithoutFiltering() throws {
        let results = try (0 ..< 5).map { try result(
            id: idEnding(String($0)),
            at: morning.addingTimeInterval(Double($0))
        ) }
        #expect(BasdaiCSV.table(results).rows.count == 5)
    }

    private func lateEvening(in zone: String) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        let parts = DateComponents(year: 2025, month: 11, day: 11, hour: 23, minute: 30)
        return try #require(calendar.date(from: parts))
    }
}
