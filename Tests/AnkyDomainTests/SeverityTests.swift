// SPDX-License-Identifier: GPL-3.0-or-later
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

    @Test(arguments: [0.0, -0.5, -Double.infinity])
    func fractionAtOrBelowZeroGivesZero(fraction: Double) {
        #expect(Severity(nearestToFraction: fraction) == Severity(0))
    }

    @Test(arguments: [1.0, 1.2, Double.infinity])
    func fractionAtOrAboveOneGivesTen(fraction: Double) {
        #expect(Severity(nearestToFraction: fraction) == Severity(10))
    }

    @Test func fractionRoundsToTheNearestLevel() {
        #expect(Severity(nearestToFraction: 0.31) == Severity(3))
        #expect(Severity(nearestToFraction: 0.69) == Severity(7))
    }

    @Test func fractionHalfwayBetweenTwoLevelsRoundsUp() {
        #expect(Severity(nearestToFraction: 0.25) == Severity(3))
        #expect(Severity(nearestToFraction: 0.75) == Severity(8))
    }

    @Test func fractionThatIsNotANumberGivesZero() {
        #expect(Severity(nearestToFraction: .nan) == Severity(0))
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
