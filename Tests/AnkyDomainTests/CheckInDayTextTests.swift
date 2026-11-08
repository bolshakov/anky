// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInDayTextTests {
    private func entry(_ kind: EntryKind, _ level: Int) throws -> Entry {
        try Entry(
            id: UUID(), kind: kind, severity: #require(Severity(level)), date: Date(timeIntervalSince1970: 0),
            note: nil, places: []
        )
    }

    private let words = CheckInInfoWords(
        taken: { "Taken \($0)." },
        before: { kind, level in "Before: \(kind.rawValue) \(level)." }
    )

    private func info(_ taken: String, before: Entry? = nil) -> String {
        CheckInDayText.infoTaken(taken: taken, before: before, words: words)
    }

    @Test func aDoseWithNoBeforeReadingReadsOnlyWhenItWasTaken() {
        #expect(info("today at 12:00 PM") == "Taken today at 12:00 PM.")
    }

    @Test(arguments: [EntryKind.pain, .stiffness, .fatigue])
    func aBeforeReadingNamesItsKindAndLevelAfterTheTakenText(kind: EntryKind) throws {
        let before = try entry(kind, 7)
        #expect(info("yesterday at 9:41 AM", before: before) ==
            "Taken yesterday at 9:41 AM. Before: \(kind.rawValue) 7.")
    }

    @Test func theTakenTextIsPassedOnAsTheSystemFormattedIt() {
        #expect(info("Nov 1, 2026 at 12:00\u{202F}PM") == "Taken Nov 1, 2026 at 12:00\u{202F}PM.")
    }

    @Test func aDoseWhoseBeforeReadingIsGoneReadsAsNoEarlierReading() throws {
        let dose = Dose(
            id: UUID(),
            medicationID: UUID(),
            takenAt: Date(timeIntervalSince1970: 0),
            beforeReadingID: UUID()
        )
        let readings = try DoseReadings(dose, in: [entry(.pain, 7)])
        #expect(info("today at 12:00 PM", before: readings.before) == "Taken today at 12:00 PM.")
    }
}
