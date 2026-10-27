import AnkyDomain
import Foundation
import Testing

struct SeverityTests {
    @Test(arguments: [0, 4, 10])
    func acceptsScoresFromZeroToTen(value: Int) {
        #expect(Severity(value)?.value == value)
    }

    @Test(arguments: [-1, 11])
    func rejectsScoresOutsideZeroToTen(value: Int) {
        #expect(Severity(value) == nil)
    }

    @Test(arguments: [0.0, 4.0, 10.0])
    func acceptsWholeNumbersFromZeroToTen(value: Double) {
        #expect(Severity(exactly: value)?.value == Int(value))
    }

    @Test(arguments: [4.5, -1.0, 11.0, Double.nan, Double.infinity])
    func rejectsFractionsAndValuesOutsideZeroToTen(value: Double) {
        #expect(Severity(exactly: value) == nil)
    }

    @Test func writesTheLevelOutOfTen() throws {
        #expect(try #require(Severity(4)).text == "4 of 10")
    }

    @Test func encodesAsABareNumber() throws {
        let data = try JSONEncoder().encode(#require(Severity(4)))
        #expect(String(data: data, encoding: .utf8) == "4")
    }

    @Test func decodesABareNumber() throws {
        let severity = try JSONDecoder().decode(Severity.self, from: Data("4".utf8))
        #expect(severity == Severity(4))
    }

    @Test(arguments: ["-1", "11"])
    func decodingOutsideZeroToTenIsDataCorrupted(json: String) throws {
        let error = try #require(throws: DecodingError.self) {
            try JSONDecoder().decode(Severity.self, from: Data(json.utf8))
        }
        guard case .dataCorrupted = error else {
            Issue.record("Expected a dataCorrupted error")
            return
        }
    }

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(severity: Int, date: Date) throws -> Entry {
        try Entry(draft: EntryDraft(severity: #require(Severity(severity)), date: date))
    }

    @Test func startLevelIsZeroWhenNothingWasSaved() {
        #expect(Severity.startLevel(after: []) == Severity(0))
    }

    @Test func startLevelIsTheLevelOfTheOnlySavedEntry() throws {
        let saved = try [entry(severity: 6, date: date)]
        #expect(Severity.startLevel(after: saved) == Severity(6))
    }

    @Test func startLevelIsTheLastSavedEntryEvenWhenItIsDatedEarlier() throws {
        let laterDated = try entry(severity: 8, date: date.addingTimeInterval(3600))
        let earlierDated = try entry(severity: 2, date: date)
        #expect(Severity.startLevel(after: [laterDated, earlierDated]) == Severity(2))
    }
}
